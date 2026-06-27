use std::io::{Cursor, Read};

use ::zip::result::ZipError;
use ::zip::ZipArchive;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum UnzipError {
    #[error("failed to read zip archive: {source}")]
    ZipRead {
        #[source]
        source: ZipError,
    },

    #[error("failed to read zip entry at index {index}: {source}")]
    ZipEntryRead {
        index: usize,
        #[source]
        source: ZipError,
    },

    #[error("failed to read zip entry name at index {index}: {source}")]
    ZipEntryName {
        index: usize,
        #[source]
        source: ZipError,
    },

    #[error("failed to extract zip entry at index {index}, name {name}: {source}")]
    ZipEntryExtract {
        index: usize,
        name: String,
        #[source]
        source: std::io::Error,
    },
}

pub struct ZipUtils {}

impl ZipUtils {
    /// Unzips the ZIP archive and returns the bytes of all regular files within.

    /// bytes: The original bytes of the zip file.

    /// Returns: The bytes of each file within the zip archive.

    /// Directories are skipped; filenames, paths, and passwords are not processed separately.
    pub fn unzip_files(bytes: Vec<u8>) -> Result<Vec<Vec<u8>>,UnzipError> {
        let cursor = Cursor::new(bytes);

        let mut archive = ZipArchive::new(cursor).map_err(|source| {
            UnzipError::ZipRead { source }
        })?;

        let mut files = Vec::new();

        for index in 0..archive.len() {
            let mut file = archive.by_index(index).map_err(|source| {
                UnzipError::ZipEntryRead { index, source }
            })?;

            if file.is_dir() {
                continue;
            }

            // Match the current zip crate signature:
            // pub fn name(&self) -> ZipResult<Cow<'_, str>>
            let name = file
                .name()
                .map_err(|source| UnzipError::ZipEntryName { index, source })?
                .into_owned();

            let mut buf = Vec::new();

            file.read_to_end(&mut buf).map_err(|source| {
                UnzipError::ZipEntryExtract {
                    index,
                    name,
                    source,
                }
            })?;

            files.push(buf);
        }

        Ok(files)
    }
}
