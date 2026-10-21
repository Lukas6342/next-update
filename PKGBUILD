# Maintainer: Lukas6342
pkgname=next-update
pkgver=0.1.0
pkgrel=1
pkgdesc='Auto update daemon for servers (systemd)'
arch=('any')
url='https://github.com/Lukas6342/next-update'
license=('MIT')
depends=('bash' 'coreutils' 'systemd')
backup=('etc/next-update/config')
source=('next-update' 'next-update.service' 'config' 'LICENSE')
sha256sums=('0cad4886a362985aa9ce427b94f4bd8a52259586cbbd004d8c78bd6616a3a347' '17ad8c567d5c6bc0eb55e92522b38f1b27f19614f31de839b430cd03e56f0d21' 'bfe13127bb3525ea49da7002a69f0270c88cbb829976d3701fd655373b9d07cf' '28aad21617e2e48a33942d31387cecc1649c43afa31284ba8f7d38a9d9286fbc')

package() {
    install -Dm755 next-update "$pkgdir/usr/bin/next-update"
    install -Dm644 next-update.service "$pkgdir/usr/lib/systemd/system/next-update.service"
    install -Dm600 config "$pkgdir/etc/next-update/config"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
