use aws_lambda_events::event::eventbridge::EventBridgeEvent;
use aws_sdk_cloudfront::types::InvalidationBatch;
use aws_sdk_cloudfront::types::Paths;
use itertools::Itertools;
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use rayon::prelude::*;
use serde_json::Value;
use tracing_subscriber::filter::{EnvFilter, LevelFilter};
use uuid::Uuid;

mod sqs;
use sqs::Sqs;

/// This is the main body for the function.
/// Write your code inside it.
/// There are some code example in the following URLs:
/// - https://github.com/awslabs/aws-lambda-rust-runtime/tree/main/examples
/// - https://github.com/aws-samples/serverless-rust-demo/
#[tracing::instrument]
async fn function_handler(event: LambdaEvent<EventBridgeEvent>) -> Result<(), anyhow::Error> {
    // Extract some useful information from the request
    let config = aws_config::load_from_env().await;
    let sqs = Sqs::new(&config);
    let mut messages = sqs.receive_messages(0).await?.unwrap_or_default();

    // If there are no messages, we can return early
    if messages.is_empty() {
        return Ok(());
    }

    // If there are more than 10 messages, we need to keep fetching them
    if messages.len() >= 10 {
        while let Some(remaining_messages) = sqs.receive_messages(5).await? {
            messages.extend(remaining_messages);
        }
    }

    let distribution_ids: Value = serde_json::from_str(
        std::env::var("DISTRIBUTION_IDS")
            .expect("environment variable `DISTRIBUTION_IDS` should be set")
            .as_str(),
    )?;
    let bucket_names: Vec<String> = messages
        .par_iter()
        .filter_map(|record| record.body.as_ref())
        .map(|body| {
            let body: Value =
                serde_json::from_str(body.as_str()).expect("body should be json format");
            body["Records"][0]["s3"]["bucket"]["name"]
                .as_str()
                .unwrap()
                .to_owned()
        })
        .collect();
    let distribution_ids: Vec<&str> = bucket_names
        .into_iter()
        .unique()
        .map(|bucket_name| {
            distribution_ids
                .get(&bucket_name)
                .unwrap_or_else(|| {
                    panic!(
                        "bucket name `{}` is not found in environment value",
                        bucket_name
                    )
                })
                .as_str()
                .unwrap()
        })
        .collect();

    let cloudfront_client = aws_sdk_cloudfront::Client::new(&config);
    for distribution_id in distribution_ids {
        send_invalidation_request(&cloudfront_client, distribution_id).await?;
    }

    sqs.delete_messages(messages).await?;

    Ok(())
}

/// Send an invalidation request to CloudFront
async fn send_invalidation_request(
    client: &aws_sdk_cloudfront::Client,
    distribution_id: &str,
) -> Result<(), anyhow::Error> {
    let paths = Paths::builder().quantity(1).items("/*").build()?;
    let invalidation_batch = InvalidationBatch::builder()
        .paths(paths)
        .caller_reference(Uuid::new_v4())
        .build()?;
    client
        .create_invalidation()
        .distribution_id(distribution_id)
        .invalidation_batch(invalidation_batch)
        .send()
        .await?;

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(LevelFilter::INFO.into())
                .from_env_lossy(),
        )
        // disable printing the name of the module in every log line.
        .with_target(false)
        // disabling time is handy because CloudWatch will add the ingestion time.
        .without_time()
        .init();

    run(service_fn(function_handler)).await
}
