# Maintainer: Wojnstup <wojnstup@protonmail.com>
pkgname="pipecat-turbo"
pkgver="1.0.0"
pkgrel="1"
license=('GPL-3.0')
pkgdesc="A tool for watching YouTube or listening to music using dmenu and mpv."
arch=("x86_64")
depends=("dmenu" "mpv" "socat" "youtube-dl")
optdepends=("libnotify: notification support")
source=("pipecat-turbo.sh")
sha512sums=("SKIP")

package(){
	mkdir -p "${pkgdir}/usr/bin"
	cp "${srcdir}/pipecat-turbo.sh" "${pkgdir}/usr/bin/pipecat-turbo"
	chmod +x "${pkgdir}/usr/bin/pipecat-turbo"
}
