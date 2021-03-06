FROM alpine:3.8 as deps
RUN apk add --no-cache libgomp zlib libpng libjpeg-turbo libwebp tiff lcms2 \
	freetype fontconfig ghostscript ghostscript-fonts \
	openexr x265

FROM deps as builder
RUN apk add --no-cache alpine-sdk automake autoconf libtool bash
RUN apk add --no-cache zlib-dev libpng-dev libjpeg-turbo-dev \
	freetype-dev fontconfig-dev ghostscript-dev libwebp-dev tiff-dev lcms2-dev \
	openexr-dev x265-dev

WORKDIR /work
RUN git clone -b frame-parallel https://github.com/strukturag/libde265.git
WORKDIR libde265
RUN ./autogen.sh && ./configure	&& make -j8 install

WORKDIR /work
RUN git clone https://github.com/strukturag/libheif.git
WORKDIR libheif
RUN ./autogen.sh && ./configure	&& make -j8 install

WORKDIR /work
RUN git clone https://github.com/ImageMagick/ImageMagick.git
WORKDIR ImageMagick
RUN ./configure --with-heic --with-jpeg --with-lcms2 --with-png --with-gslib --with-openexr --with-tiff --with-zlib --with-gs-font-dir=/usr/share/fonts/Type1 --with-threads --with-webp --without-x --disable-cipher --without-magick-plus-plus --without-pango --without-perl
RUN make -j8 install

FROM deps
COPY --from=builder /usr/local/lib/libde265.so.1 /usr/local/lib/libde265.so.1
COPY --from=builder /usr/local/lib/libheif.so.1 /usr/local/lib/libheif.so.1

COPY --from=builder /usr/local/lib/libMagickCore-7.Q16HDRI.so.6 /usr/local/lib/libMagickCore-7.Q16HDRI.so.6
COPY --from=builder /usr/local/lib/libMagickWand-7.Q16HDRI.so.6 /usr/local/lib/libMagickWand-7.Q16HDRI.so.6
COPY --from=builder /usr/local/lib/ImageMagick-7.0.8/ /usr/local/lib/ImageMagick-7.0.8/
COPY --from=builder /usr/local/etc/ImageMagick-7/ /usr/local/etc/ImageMagick-7/
COPY --from=builder /usr/local/bin/magick /usr/local/bin/magick

RUN ln -s /usr/local/bin/magick /usr/local/bin/convert
