#!/bin/bash
set -e
ASTERISK_VERSION=20.7.0
CPU_CORES=$(nproc)
INSTALL_DIR=/usr/src

echo "=== 🚀 Iniciando Instalação do Asterisk ${ASTERISK_VERSION} ==="

# --- Seção 1: Atualização e Dependências ---

echo "=== Atualizando sistema e instalando dependências ==="
dnf clean all -y
dnf update -y

# Instalação das ferramentas de desenvolvimento e todas as bibliotecas necessárias
dnf install -y epel-release
dnf groupinstall -y "Development Tools"

dnf install -y \
  ncurses-devel \
  libedit-devel \
  libuuid-devel \
  jansson-devel \
  libxml2-devel \
  sqlite-devel \
  openssl-devel \
  libcurl-devel \
  speex-devel \
  speexdsp-devel \
  gsm-devel \
  opus-devel \
  portaudio-devel \
  libogg-devel \
  libvorbis-devel \
  newt-devel \
  lua-devel \
  pipewire-jack-audio-connection-kit-devel \
  alsa-lib-devel \
  libical-devel \
  popt-devel \
  neon-devel \
  libusb1-devel \
  libpq-devel \
  unixODBC unixODBC-devel \
  git subversion \
  doxygen \
  libtool \
  binutils-devel \
  libsamplerate-devel \
  libsrtp-devel \
  bluez-libs-devel \
  snappy-devel \
  libxslt-devel \
  freetds-devel \
  openldap-devel \
  mariadb-connector-c-devel \
  curl \
  wget \
  tar \
  which \
  python3-devel

dnf install epel-release -y
dnf install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y
dnf install ffmpeg ffmpeg-devel -y
dnf install libvpx-devel -y
# --- Seção 2: Download e Configuração ---

echo "=== Baixando e extraindo Asterisk ${ASTERISK_VERSION} ==="
cd $INSTALL_DIR
wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz
tar -xzf asterisk-${ASTERISK_VERSION}.tar.gz
cd asterisk-${ASTERISK_VERSION}
contrib/scripts/install_prereq install

echo "=== Executando o script 'configure' ==="
# O 'configure' agora deve passar, pois a dependência libedit-devel está instalada
./configure --with-pjproject-bundled --with-jansson-bundled=yes --libdir=/usr/lib64

# --- Seção 3: Menuselect Corrigido ---

echo "=== Configurando opções do menuselect ==="
make menuselect.makeopts

# Lista de módulos a serem habilitados
MODULE_OPTIONS="app_queue res_odbc res_config_odbc cdr_adaptive_odbc codec_a_mu codec_speex codec_ulaw codec_opus codec_silk codec_siren7 codec_siren14 codec_g729a format_g719 format_g723 format_g726 format_g729 format_gsm format_h263 format_h264 format_ilbc format_ogg_vorbis format_pcm format_siren14 format_siren7 format_sln format_wav format_wav_gsm"

for opt in $MODULE_OPTIONS; do
  echo "Habilitando módulo/formato: $opt"
  # O '|| true' garante que o script não pare se um módulo não existir na versão
  menuselect/menuselect --enable $opt menuselect.makeopts || true
done

# Desabilita otimizações nativas (BUILD_NATIVE) e sons
menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts
menuselect/menuselect --disable-category MENUSELECT_CORE_SOUNDS menuselect.makeopts
menuselect/menuselect --disable-category MENUSELECT_EXTRA_SOUNDS menuselect.makeopts

# --- Seção 4: Compilação e Instalação ---

echo "=== Compilando Asterisk (usando ${CPU_CORES} núcleos) ==="
make -j${CPU_CORES}

echo "=== Instalando Binários, Arquivos de Exemplo e Serviço ==="
make install
mkdir -p /var/lib/asterisk/sounds/moh
mkdir -p /var/lib/asterisk/sounds/dial
ldconfig # Atualiza o cache de bibliotecas
cp ${INSTALL_DIR}/asterisk-${ASTERISK_VERSION}/contrib/systemd/asterisk.service /etc/systemd/system/
setenforce 0
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
groupadd -r asterisk
useradd -r -s /sbin/nologin -g asterisk asterisk
chown -R asterisk:asterisk /var/spool/asterisk /var/run/asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk

systemctl daemon-reload
systemctl enable asterisk
#systemctl start asterisk

# --- Seção 5: Finalização ---

echo "=== Configurando timezone ==="
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
echo "America/Sao_Paulo" > /etc/timezone

echo "=== Limpando arquivos temporários ==="
cd /
rm -rf ${INSTALL_DIR}/asterisk-${ASTERISK_VERSION}*

echo "========================================================"
echo "=== Asterisk ${ASTERISK_VERSION} instalado com sucesso! 🎉 ==="
echo "========================================================"
echo "Próximos passos:"
echo "1. Para iniciar o serviço: **systemctl start asterisk**"
echo "2. Para habilitar na inicialização: **systemctl enable asterisk**"
echo "3. Para acessar o CLI: **asterisk -rvvv**"
