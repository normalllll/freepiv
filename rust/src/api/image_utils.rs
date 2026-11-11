use ::gif::{Encoder, Frame, Repeat};
use fast_image_resize::{
    images::Image as ResizedImage, FilterType as ResizeFilter, IntoImageView, ResizeAlg,
    ResizeOptions, Resizer,
};
use image::{
    codecs::jpeg::JpegEncoder, imageops::FilterType, DynamicImage, ExtendedColorType,
    GenericImageView, ImageDecoder, ImageReader, Limits, RgbImage, RgbaImage,
};
use std::io::Cursor;
use thiserror::Error;

/// Longest edge of a source image `prepare_profile_image` will decode.
const PROFILE_SOURCE_MAX_EDGE: u32 = 16_384;
/// Largest pixel count of a source image `prepare_profile_image` will decode.
const PROFILE_SOURCE_MAX_PIXELS: u64 = 100_000_000;
/// Memory the decoder may use for one source image.
const PROFILE_DECODE_MAX_ALLOC: u64 = 512 * 1024 * 1024;
/// Edge of the uploaded square; a smaller crop is not enlarged.
const PROFILE_OUTPUT_MAX_SIDE: u32 = 1024;
/// Largest encoded size pixiv accepts for a profile image.
const PROFILE_OUTPUT_MAX_BYTES: usize = 4 * 1024 * 1024;
/// JPEG qualities tried in order until the result fits.
const PROFILE_JPEG_QUALITIES: [u8; 3] = [90, 80, 70];

/// Why a profile image could not be prepared.
#[derive(Debug, Error)]
pub enum ProfileImageError {
    #[error("failed to decode the image: {message}")]
    Decode { message: String },

    #[error("image is too large to decode: {width}x{height}")]
    SourceTooLarge { width: u32, height: u32 },

    #[error("crop side must not be zero")]
    EmptyCrop,

    #[error("failed to encode the image: {message}")]
    Encode { message: String },

    #[error("encoded image is {size} bytes, over the {limit} byte limit")]
    OutputTooLarge { size: u64, limit: u64 },
}


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

    /// Crops, shrinks and compresses a picked image into the JPEG uploaded as a
    /// profile image.
    ///
    /// source: The raw bytes of a jpg/png/webp/gif image; a gif contributes its
    /// first frame.
    ///
    /// x, y, side: The square to keep, in pixels of the image as it is shown,
    /// that is after its EXIF orientation is applied. A square that leaves the
    /// image is moved and shrunk to fit.
    ///
    /// Returns: JPEG file bytes, at most 1024 pixels square.
    pub fn prepare_profile_image(
        source: Vec<u8>,
        x: u32,
        y: u32,
        side: u32,
    ) -> Result<Vec<u8>, ProfileImageError> {
        let image = eight_bit_rgb_or_rgba(decode_oriented(&source)?);
        let (width, height) = image.dimensions();
        let (x, y, side) =
            clamp_crop(x, y, side, width, height).ok_or(ProfileImageError::EmptyCrop)?;
        let square = crop_to_square(&image, x, y, side, side.min(PROFILE_OUTPUT_MAX_SIDE));
        let rgb = match square {
            DynamicImage::ImageRgb8(rgb) => rgb,
            with_alpha => flatten_on_white(&with_alpha),
        };
        encode_jpeg_within(&rgb, PROFILE_OUTPUT_MAX_BYTES)
    }
}

/// The image as 8-bit RGB, or 8-bit RGBA when it has transparency; one of
/// these is already what most sources decode to, and is kept without a copy.
fn eight_bit_rgb_or_rgba(image: DynamicImage) -> DynamicImage {
    match image {
        DynamicImage::ImageRgb8(_) | DynamicImage::ImageRgba8(_) => image,
        other if other.color().has_alpha() => DynamicImage::ImageRgba8(other.to_rgba8()),
        other => DynamicImage::ImageRgb8(other.to_rgb8()),
    }
}

/// The `side` square at (`x`, `y`) of an 8-bit RGB or RGBA `image`, scaled to
/// `target` pixels square with Lanczos3; copied as it is when `target` is
/// `side`. The square must lie inside the image.
fn crop_to_square(image: &DynamicImage, x: u32, y: u32, side: u32, target: u32) -> DynamicImage {
    // Both pixel types are ones the resizer takes, the square is inside the
    // image and the output matches the source type, so resizing cannot fail.
    let pixel_type = image
        .pixel_type()
        .expect("an 8-bit RGB or RGBA image has a resizer pixel type");
    let mut output = ResizedImage::new(target, target, pixel_type);
    let algorithm = if target == side {
        ResizeAlg::Nearest
    } else {
        ResizeAlg::Convolution(ResizeFilter::Lanczos3)
    };
    let options = ResizeOptions::new()
        .crop(f64::from(x), f64::from(y), f64::from(side), f64::from(side))
        .resize_alg(algorithm);
    Resizer::new()
        .resize(image, &mut output, &options)
        .expect("a square inside the image resizes into its own pixel type");
    let pixels = output.into_vec();
    let size_matches = "the resized buffer holds target x target pixels";
    match image {
        DynamicImage::ImageRgba8(_) => DynamicImage::ImageRgba8(
            RgbaImage::from_raw(target, target, pixels).expect(size_matches),
        ),
        _ => DynamicImage::ImageRgb8(
            RgbImage::from_raw(target, target, pixels).expect(size_matches),
        ),
    }
}

fn decode_error(error: impl std::fmt::Display) -> ProfileImageError {
    ProfileImageError::Decode {
        message: error.to_string(),
    }
}

/// Decodes the first frame of an image and turns it the way it is displayed.
fn decode_oriented(source: &[u8]) -> Result<DynamicImage, ProfileImageError> {
    let mut reader = ImageReader::new(Cursor::new(source))
        .with_guessed_format()
        .map_err(decode_error)?;
    let mut limits = Limits::default();
    limits.max_image_width = Some(PROFILE_SOURCE_MAX_EDGE);
    limits.max_image_height = Some(PROFILE_SOURCE_MAX_EDGE);
    limits.max_alloc = Some(PROFILE_DECODE_MAX_ALLOC);
    reader.limits(limits);
    let mut decoder = reader.into_decoder().map_err(|error| match error {
        image::ImageError::Limits(_) => ProfileImageError::SourceTooLarge {
            width: 0,
            height: 0,
        },
        error => decode_error(error),
    })?;
    let (width, height) = decoder.dimensions();
    if width > PROFILE_SOURCE_MAX_EDGE
        || height > PROFILE_SOURCE_MAX_EDGE
        || u64::from(width) * u64::from(height) > PROFILE_SOURCE_MAX_PIXELS
    {
        return Err(ProfileImageError::SourceTooLarge { width, height });
    }
    let orientation = decoder.orientation().map_err(decode_error)?;
    let mut image = DynamicImage::from_decoder(decoder).map_err(decode_error)?;
    image.apply_orientation(orientation);
    Ok(image)
}

/// The square `(x, y, side)` that lies inside a `width` x `height` image: the
/// side is cut down to the short edge, then the corner is moved back inside.
/// `None` when nothing is left to keep.
fn clamp_crop(x: u32, y: u32, side: u32, width: u32, height: u32) -> Option<(u32, u32, u32)> {
    let side = side.min(width).min(height);
    if side == 0 {
        return None;
    }
    Some((x.min(width - side), y.min(height - side), side))
}

/// Pixels with some transparency become that much of the pixel over white.
fn flatten_on_white(image: &DynamicImage) -> RgbImage {
    let rgba = image.to_rgba8();
    let mut rgb = RgbImage::new(rgba.width(), rgba.height());
    for (from, to) in rgba.pixels().zip(rgb.pixels_mut()) {
        let alpha = u32::from(from[3]);
        for channel in 0..3 {
            let over = u32::from(from[channel]) * alpha + 255 * (255 - alpha);
            to[channel] = (over / 255) as u8;
        }
    }
    rgb
}

fn encode_jpeg(image: &RgbImage, quality: u8) -> Result<Vec<u8>, ProfileImageError> {
    let mut output = Vec::new();
    JpegEncoder::new_with_quality(&mut output, quality)
        .encode(
            image.as_raw(),
            image.width(),
            image.height(),
            ExtendedColorType::Rgb8,
        )
        .map_err(|error| ProfileImageError::Encode {
            message: error.to_string(),
        })?;
    Ok(output)
}

/// The first of `PROFILE_JPEG_QUALITIES` whose JPEG is at most `limit` bytes.
fn encode_jpeg_within(image: &RgbImage, limit: usize) -> Result<Vec<u8>, ProfileImageError> {
    let mut smallest = usize::MAX;
    for quality in PROFILE_JPEG_QUALITIES {
        let output = encode_jpeg(image, quality)?;
        if output.len() <= limit {
            return Ok(output);
        }
        smallest = output.len();
    }
    Err(ProfileImageError::OutputTooLarge {
        size: smallest as u64,
        limit: limit as u64,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageFormat, Rgba, RgbaImage};

    fn encode(image: &DynamicImage, format: ImageFormat) -> Vec<u8> {
        let mut bytes = Vec::new();
        image
            .write_to(&mut Cursor::new(&mut bytes), format)
            .expect("encode test image");
        bytes
    }

    fn decode(bytes: &[u8]) -> RgbImage {
        image::load_from_memory(bytes)
            .expect("decode result")
            .to_rgb8()
    }

    /// A JPEG whose left half is red and right half blue, tagged with an EXIF
    /// orientation (6: shown turned a quarter clockwise).
    fn oriented_jpeg(orientation: u16) -> Vec<u8> {
        let mut plain = RgbImage::new(40, 20);
        for (x, _, pixel) in plain.enumerate_pixels_mut() {
            *pixel = if x < 20 {
                image::Rgb([255, 0, 0])
            } else {
                image::Rgb([0, 0, 255])
            };
        }
        let jpeg = encode_jpeg(&plain, 95).expect("encode");
        let mut tiff = b"MM\0\x2A\0\0\0\x08".to_vec();
        tiff.extend_from_slice(&1u16.to_be_bytes());
        tiff.extend_from_slice(&0x0112u16.to_be_bytes());
        tiff.extend_from_slice(&3u16.to_be_bytes());
        tiff.extend_from_slice(&1u32.to_be_bytes());
        tiff.extend_from_slice(&orientation.to_be_bytes());
        tiff.extend_from_slice(&[0, 0]);
        tiff.extend_from_slice(&0u32.to_be_bytes());
        let mut segment = b"Exif\0\0".to_vec();
        segment.extend_from_slice(&tiff);
        let mut out = jpeg[..2].to_vec();
        out.extend_from_slice(&[0xFF, 0xE1]);
        out.extend_from_slice(&((segment.len() + 2) as u16).to_be_bytes());
        out.extend_from_slice(&segment);
        out.extend_from_slice(&jpeg[2..]);
        out
    }

    /// Pseudo-random noise, which JPEG cannot shrink much.
    fn noise(side: u32) -> RgbImage {
        let mut state = 0x2545_f491_u32;
        RgbImage::from_fn(side, side, |_, _| {
            let mut next = || {
                state ^= state << 13;
                state ^= state >> 17;
                state ^= state << 5;
                (state >> 8) as u8
            };
            image::Rgb([next(), next(), next()])
        })
    }

    #[test]
    fn crop_stays_inside_the_image() {
        assert_eq!(clamp_crop(10, 20, 30, 100, 80), Some((10, 20, 30)));
        assert_eq!(clamp_crop(90, 70, 30, 100, 80), Some((70, 50, 30)));
        assert_eq!(clamp_crop(5, 5, 500, 100, 80), Some((5, 0, 80)));
        assert_eq!(clamp_crop(0, 0, 0, 100, 80), None);
        assert_eq!(clamp_crop(0, 0, 10, 0, 80), None);
    }

    #[test]
    fn output_is_a_square_jpeg_of_the_cropped_area() {
        let mut source = RgbaImage::from_pixel(60, 40, Rgba([255, 0, 0, 255]));
        for y in 0..40 {
            for x in 30..60 {
                source.put_pixel(x, y, Rgba([0, 0, 255, 255]));
            }
        }
        let bytes = encode(&DynamicImage::ImageRgba8(source), ImageFormat::Png);
        let output = ImageUtils::prepare_profile_image(bytes, 25, 0, 40).expect("prepare");
        assert_eq!(&output[..2], &[0xFF, 0xD8]);
        let result = decode(&output);
        assert_eq!(result.dimensions(), (40, 40));
        let left = result.get_pixel(2, 20);
        let right = result.get_pixel(37, 20);
        assert!(left[0] > 200 && left[2] < 60, "left is red: {left:?}");
        assert!(right[2] > 200 && right[0] < 60, "right is blue: {right:?}");
    }

    #[test]
    fn large_crops_shrink_to_the_output_edge() {
        let source =
            DynamicImage::ImageRgb8(RgbImage::from_pixel(1500, 1200, image::Rgb([9, 99, 9])));
        let bytes = encode(&source, ImageFormat::Png);
        let output = ImageUtils::prepare_profile_image(bytes, 0, 0, 1200).expect("prepare");
        assert_eq!(decode(&output).dimensions(), (1024, 1024));
    }

    #[test]
    fn crop_follows_the_exif_orientation() {
        // Shown turned a quarter clockwise, the 40x20 picture is 20x40 with the
        // red half on top; the square at y = 20 is the blue bottom half.
        let bytes = oriented_jpeg(6);
        let shown = decode_oriented(&bytes).expect("decode");
        assert_eq!(shown.dimensions(), (20, 40));
        let output = ImageUtils::prepare_profile_image(bytes.clone(), 0, 20, 20).expect("prepare");
        let blue = *decode(&output).get_pixel(10, 10);
        assert!(blue[2] > 200 && blue[0] < 60, "bottom is blue: {blue:?}");
        let output = ImageUtils::prepare_profile_image(bytes, 0, 0, 20).expect("prepare");
        let red = *decode(&output).get_pixel(10, 10);
        assert!(red[0] > 200 && red[2] < 60, "top is red: {red:?}");
    }

    #[test]
    fn transparency_is_flattened_onto_white() {
        let mut source = RgbaImage::from_pixel(20, 20, Rgba([0, 0, 0, 0]));
        for y in 0..20 {
            for x in 10..20 {
                source.put_pixel(x, y, Rgba([0, 0, 0, 255]));
            }
        }
        let bytes = encode(&DynamicImage::ImageRgba8(source), ImageFormat::Png);
        let output = ImageUtils::prepare_profile_image(bytes, 0, 0, 20).expect("prepare");
        let result = decode(&output);
        let clear = *result.get_pixel(3, 10);
        let solid = *result.get_pixel(16, 10);
        assert!(clear.0.iter().all(|c| *c > 245), "clear is white: {clear:?}");
        assert!(solid.0.iter().all(|c| *c < 12), "solid stays black: {solid:?}");
    }

    #[test]
    fn half_transparent_pixels_mix_with_white() {
        let source = DynamicImage::ImageRgba8(RgbaImage::from_pixel(2, 2, Rgba([0, 0, 0, 128])));
        let flat = flatten_on_white(&source);
        assert_eq!(flat.get_pixel(0, 0).0, [127, 127, 127]);
    }

    #[test]
    fn transparency_is_flattened_after_shrinking() {
        let mut source = RgbaImage::from_pixel(2048, 2048, Rgba([255, 0, 0, 0]));
        for y in 0..2048 {
            for x in 1024..2048 {
                source.put_pixel(x, y, Rgba([0, 0, 0, 255]));
            }
        }
        let bytes = encode(&DynamicImage::ImageRgba8(source), ImageFormat::Png);
        let output = ImageUtils::prepare_profile_image(bytes, 0, 0, 2048).expect("prepare");
        let result = decode(&output);
        assert_eq!(result.dimensions(), (1024, 1024));
        // A clear pixel's hidden red must not bleed into the white.
        let clear = *result.get_pixel(200, 512);
        let solid = *result.get_pixel(800, 512);
        assert!(clear.0.iter().all(|c| *c > 245), "clear is white: {clear:?}");
        assert!(solid.0.iter().all(|c| *c < 12), "solid stays black: {solid:?}");
    }

    #[test]
    fn grey_and_sixteen_bit_sources_are_prepared() {
        let grey = DynamicImage::ImageLuma8(image::GrayImage::from_pixel(1500, 1500, image::Luma([200])));
        let output =
            ImageUtils::prepare_profile_image(encode(&grey, ImageFormat::Png), 0, 0, 1500)
                .expect("prepare grey");
        let pixel = *decode(&output).get_pixel(512, 512);
        assert!(pixel.0.iter().all(|c| c.abs_diff(200) < 4), "grey stays grey: {pixel:?}");

        let deep = DynamicImage::ImageRgba16(image::ImageBuffer::from_pixel(
            30,
            30,
            Rgba([0u16, 0, 65535, 65535]),
        ));
        let output =
            ImageUtils::prepare_profile_image(encode(&deep, ImageFormat::Png), 0, 0, 30)
                .expect("prepare 16-bit");
        let pixel = *decode(&output).get_pixel(15, 15);
        assert!(pixel[2] > 240 && pixel[0] < 12, "blue stays blue: {pixel:?}");
    }

    #[test]
    fn a_gif_gives_its_first_frame() {
        let mut bytes = Vec::new();
        {
            let mut encoder = Encoder::new(&mut bytes, 16, 16, &[]).expect("gif");
            for color in [[255u8, 0, 0], [0, 0, 255]] {
                let mut rgba: Vec<u8> = (0..16 * 16)
                    .flat_map(|_| [color[0], color[1], color[2], 255])
                    .collect();
                let frame = Frame::from_rgba_speed(16, 16, &mut rgba, 10);
                encoder.write_frame(&frame).expect("frame");
            }
        }
        let output = ImageUtils::prepare_profile_image(bytes, 0, 0, 16).expect("prepare");
        let pixel = *decode(&output).get_pixel(8, 8);
        assert!(pixel[0] > 200 && pixel[2] < 60, "first frame is red: {pixel:?}");
    }

    #[test]
    fn oversized_sources_are_refused() {
        let wide = DynamicImage::ImageRgb8(RgbImage::new(PROFILE_SOURCE_MAX_EDGE + 1, 1));
        let bytes = encode(&wide, ImageFormat::Png);
        assert!(matches!(
            ImageUtils::prepare_profile_image(bytes, 0, 0, 1),
            Err(ProfileImageError::SourceTooLarge { .. })
        ));
    }

    #[test]
    fn undecodable_sources_are_refused() {
        assert!(matches!(
            ImageUtils::prepare_profile_image(b"not an image".to_vec(), 0, 0, 10),
            Err(ProfileImageError::Decode { .. })
        ));
        assert!(matches!(
            ImageUtils::prepare_profile_image(Vec::new(), 0, 0, 10),
            Err(ProfileImageError::Decode { .. })
        ));
    }

    #[test]
    fn an_empty_crop_is_refused() {
        let bytes = encode(
            &DynamicImage::ImageRgb8(RgbImage::new(8, 8)),
            ImageFormat::Png,
        );
        assert!(matches!(
            ImageUtils::prepare_profile_image(bytes, 0, 0, 0),
            Err(ProfileImageError::EmptyCrop)
        ));
    }

    #[test]
    fn quality_drops_until_the_result_fits() {
        let image = noise(256);
        let sizes: Vec<usize> = PROFILE_JPEG_QUALITIES
            .iter()
            .map(|quality| encode_jpeg(&image, *quality).expect("encode").len())
            .collect();
        assert!(sizes[0] > sizes[1] && sizes[1] > sizes[2], "{sizes:?}");

        let fits_first = encode_jpeg_within(&image, sizes[0]).expect("first");
        assert_eq!(fits_first.len(), sizes[0]);
        let fits_second = encode_jpeg_within(&image, sizes[0] - 1).expect("second");
        assert_eq!(fits_second.len(), sizes[1]);
        let fits_third = encode_jpeg_within(&image, sizes[1] - 1).expect("third");
        assert_eq!(fits_third.len(), sizes[2]);
        assert!(matches!(
            encode_jpeg_within(&image, sizes[2] - 1),
            Err(ProfileImageError::OutputTooLarge { .. })
        ));
    }
}