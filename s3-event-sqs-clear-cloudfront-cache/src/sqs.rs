use anyhow::Result;
use aws_config::SdkConfig;
use aws_sdk_sqs::types::{DeleteMessageBatchRequestEntry, Message};
use aws_sdk_sqs::Client;
use rayon::prelude::*;

pub struct Sqs {
    client: Client,
    queue_url: String,
}

impl Sqs {
    pub fn new(config: &SdkConfig) -> Self {
        let queue_url =
            std::env::var("QUEUE_URL").expect("environment variable `QUEUE_URL` should be set");
        let client = Client::new(config);

        Self { client, queue_url }
    }

    pub async fn receive_messages(&self, wait_time_seconds: i32) -> Result<Option<Vec<Message>>> {
        let receive_message_output = self
            .client
            .receive_message()
            .queue_url(&self.queue_url)
            .wait_time_seconds(wait_time_seconds)
            .max_number_of_messages(10)
            .visibility_timeout(30)
            .send()
            .await?;
        Ok(receive_message_output.messages)
    }

    pub async fn delete_messages(&self, messages: Vec<Message>) -> Result<()> {
        let entries = messages
            .into_par_iter()
            .filter_map(|message| {
                DeleteMessageBatchRequestEntry::builder()
                    .id(message.message_id.unwrap_or_default())
                    .receipt_handle(message.receipt_handle.unwrap_or_default())
                    .build()
                    .ok()
            })
            .collect();
        self.client
            .delete_message_batch()
            .queue_url(&self.queue_url)
            .set_entries(Some(entries))
            .send()
            .await?;

        Ok(())
    }
}
