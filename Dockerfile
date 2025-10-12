# Use a imagem oficial do Debian como base
FROM debian:bookworm

# Instale as dependências necessárias para compilar o Asterisk e o menuselect
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses5-dev \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    wget \
    tar \
    aptitude \
    --no-install-recommends
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev libz-dev libssl-dev libxml2-dev libsqlite3-dev uuid-dev \
    libcurl4-openssl-dev libspeex-dev libspeexdsp-dev libogg-dev libvorbis-dev \
    libasound2-dev portaudio19-dev libpq-dev unixodbc unixodbc-dev odbc-postgresql \
    libneon27-dev libusb-dev liblua5.1-0-dev lua5.1 \
    libgtk2.0-dev libbluetooth-dev freetds-dev libsnmp-dev libiksemel-dev libopus-dev libogg-dev \
    libnewt-dev libpopt-dev libical-dev libspandsp-dev libjack-dev \
    libsamplerate0-dev binutils-dev libsrtp2-dev libgsm1-dev libedit-dev \
    doxygen libjansson-dev libldap-dev subversion git libxslt1-dev automake \
    libncurses5-dev python3-dev libmariadb-dev libmariadb-dev-compat \
    && rm -rf /var/lib/apt/lists/*


# Defina a versão do Asterisk que você deseja instalar
ENV ASTERISK_VERSION=20.7.0

# Baixe, descompacte e compile o Asterisk
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz
RUN tar -xzvf asterisk-${ASTERISK_VERSION}.tar.gz \
    && rm asterisk-${ASTERISK_VERSION}.tar.gz \
    && cd asterisk-${ASTERISK_VERSION} \
    && ./configure --with-pjproject-bundled --with-jansson-bundled=yes --libdir=/usr/lib/x86_64-linux-gnu/ \
    && make menuselect \
    && make menuselect.makeopts \
    \
    # Habilita filas e CDR
    && menuselect/menuselect --enable app_queue menuselect.makeopts \
    && menuselect/menuselect --enable res_odbc menuselect.makeopts \
    && menuselect/menuselect --enable res_config_odbc menuselect.makeopts \
    && menuselect/menuselect --enable cdr_adaptive_odbc menuselect.makeopts \
    \
    # Habilita codecs
    && menuselect/menuselect --enable codec_a_mu menuselect.makeopts \
    && menuselect/menuselect --enable codec_speex menuselect.makeopts \
    && menuselect/menuselect --enable codec_ulaw menuselect.makeopts \
    && menuselect/menuselect --enable codec_opus menuselect.makeopts \
    && menuselect/menuselect --enable codec_silk menuselect.makeopts \
    && menuselect/menuselect --enable codec_siren7 menuselect.makeopts \
    && menuselect/menuselect --enable codec_siren14 menuselect.makeopts \
    && menuselect/menuselect --enable codec_g729a menuselect.makeopts \
    \
    # Habilita formatos
    && menuselect/menuselect --enable format_g719 menuselect.makeopts \
    && menuselect/menuselect --enable format_g723 menuselect.makeopts \
    && menuselect/menuselect --enable format_g726 menuselect.makeopts \
    && menuselect/menuselect --enable format_g729 menuselect.makeopts \
    && menuselect/menuselect --enable format_gsm menuselect.makeopts \
    && menuselect/menuselect --enable format_h263 menuselect.makeopts \
    && menuselect/menuselect --enable format_h264 menuselect.makeopts \
    && menuselect/menuselect --enable format_ilbc menuselect.makeopts \
    && menuselect/menuselect --enable format_ogg_vorbis menuselect.makeopts \
    && menuselect/menuselect --enable format_pcm menuselect.makeopts \
    && menuselect/menuselect --enable format_siren14 menuselect.makeopts \
    && menuselect/menuselect --enable format_siren7 menuselect.makeopts \
    && menuselect/menuselect --enable format_sln menuselect.makeopts \
    && menuselect/menuselect --enable format_wav menuselect.makeopts \
    && menuselect/menuselect --enable format_wav_gsm menuselect.makeopts \

    \
    #Desabilita coisas
    && menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts \
    && menuselect/menuselect --disable-category MENUSELECT_CORE_SOUNDS menuselect.makeopts \
    && menuselect/menuselect --disable-category MENUSELECT_EXTRA_SOUNDS menuselect.makeopts \
    \
    # Compile e instale
    && make -j$(nproc) \
    && make install \
    && make samples \
    && make config \
    && echo "/usr/lib" > /etc/ld.so.conf.d/asterisk.conf \
    && ldconfig -v \
    && find /usr -name "libasteriskssl.so*"

COPY ./modules/*.so /usr/lib/x86_64-linux-gnu/asterisk/modules/
RUN mkdir -p /var/lib/asterisk/documentation/thirdparty/
COPY ./modules/*.xml /var/lib/asterisk/documentation/thirdparty/


RUN apt-get update && apt-get install -y tzdata
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timez

# Exponha a porta SIP padrão
# EXPOSE 5060/udp 5060/tcp 8088/tcp 8089/tcp
EXPOSE 4569/udp \    
       5038/tcp \    
       5039/tcp \    
       5060/udp \    
       5060/tcp \    
       5061/tcp \    
       8088/tcp \    
       8089/tcp \    
       10000-20000/udp
# Defina o diretório de trabalho
WORKDIR /etc/asterisk

# Comando para iniciar o Asterisk quando o contêiner for executado
CMD ["asterisk", "-fvvvv"]
