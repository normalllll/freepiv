use ::gif::{Encoder, Frame, Repeat};
use image::{imageops::FilterType, GenericImageView};
use thiserror::Error;


#[derive(Debug, Error)]
pub enum GifError {
    #[error("images is empty")]
    EmptyImages,

    #[error("delays length must equal images length: images={images_len}, delays={delays_len}")]
    DelayLengthMismatch {
        images_len: usize,
        delays_len: usize,
    },

    #[error("invalid image size: {width}x{height}")]
    InvalidImageSize {
        width: u32,
        height: u32,
    },

    #[error("gif size too large: {width}x{height}, max is {max_width}x{max_height}")]
    GifSizeTooLarge {
        width: u32,
        height: u32,
        max_width: u32,
        max_height: u32,
    },

    #[error("failed to decode image at index {index}: {source}")]
    ImageDecode {
        index: usize,
        #[source]
        source: image::ImageError,
    },

    #[error("failed to encode gif: {source}")]
    GifEncode {
        #[from]
        source: ::gif::EncodingError,
    },
}

pub struct ImageUtils{

}

impl ImageUtils{
    /// Combines multiple images into a GIF.

    /// images: The raw bytes of each image, such as png/jpg/webp, etc.

    /// delays: The delay per frame, in milliseconds.

    /// Returns: GIF file bytes.
    pub fn images_to_gif(images: Vec<Vec<u8>>, delays: Vec<i32>) -> Result<Vec<u8>,GifError> {
        if images.is_empty() {
            return Err(GifError::EmptyImages);
        }

        if delays.len() != images.len() {
            return Err(GifError::DelayLengthMismatch {
                images_len: images.len(),
                delays_len: delays.len(),
            });
        }

        let first_img = image::load_from_memory(&images[0]).map_err(|source| {
            GifError::ImageDecode { index: 0, source }
        })?;

        let (width, height) = first_img.dimensions();

        if width == 0 || height == 0 {
            return Err(GifError::InvalidImageSize { width, height });
        }

        if width > u16::MAX as u32 || height > u16::MAX as u32 {
            return Err(GifError::GifSizeTooLarge {
                width,
                height,
                max_width: u16::MAX as u32,
                max_height: u16::MAX as u32,
            });
        }

        let mut output = Vec::new();

        {
            let mut encoder = Encoder::new(
                &mut output,
                width as u16,
                height as u16,
                &[],
            )?;

            encoder.set_repeat(Repeat::Infinite)?;

            for (index, bytes) in images.iter().enumerate() {
                let img = if index == 0 {
                    first_img.clone()
                } else {
                    image::load_from_memory(bytes).map_err(|source| {
                        GifError::ImageDecode { index, source }
                    })?
                };

                //Each frame of the GIF must be the same size; here, they are all scaled to the size of the first image.
                let img = if img.dimensions() != (width, height) {
                    img.resize_exact(width, height, FilterType::Lanczos3)
                } else {
                    img
                };

                let mut rgba = img.to_rgba8().into_raw();


                let mut frame = Frame::from_rgba_speed(
                    width as u16,
                    height as u16,
                    &mut rgba,
                    5,
                );


                let delay_ms = delays[index].max(0) as u32;
                frame.delay = ((delay_ms + 9) / 10).min(u16::MAX as u32) as u16;

                encoder.write_frame(&frame)?;
            }
        }

        Ok(output)
    }
}