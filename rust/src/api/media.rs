use crate::frb_generated::StreamSink;
use futures_util::StreamExt;
use std::collections::HashMap;

pub struct MediaChunk {
    pub bytes: Vec<u8>,
    pub received: u64,
    pub total: Option<u64>,
}

pub async fn stream_media(
    url: String,
    proxy: Option<String>,
    headers: HashMap<String, String>,
    sink: StreamSink<MediaChunk>,
) -> Result<(), String> {
    let mut stream = pixiv_rs::media::stream_media(url, proxy, headers)?;
    while let Some(chunk) = stream.next().await {
        let chunk = chunk?;
        if sink
            .add(MediaChunk {
                bytes: chunk.bytes,
                received: chunk.received,
                total: chunk.total,
            })
            .is_err()
        {
            break;
        }
    }
    Ok(())
}
