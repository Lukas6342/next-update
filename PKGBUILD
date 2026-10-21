# Maintainer: Lukas6342
pkgbase=next-update
pkgname=('next-update' 'next-update-server')
pkgver=0.2.0
pkgrel=1
arch=('any')
url='https://github.com/Lukas6342/next-update'
license=('MIT')
source=('next-update' 'next-update.service' 'next-update.conf'
        'next-update-server' 'next-update-server.service' 'next-update-server.conf'
        'LICENSE')
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package_next-update() {
    pkgdesc='Auto update daemon for servers (systemd), optionally managed by next-update-server'
    depends=('systemd' 'curl' 'pacman-contrib')
    backup=('etc/next-update/config')

    install -Dm755 next-update "$pkgdir/usr/bin/next-update"
    install -Dm644 next-update.service "$pkgdir/usr/lib/systemd/system/next-update.service"
    install -Dm600 next-update.conf "$pkgdir/etc/next-update/config"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

package_next-update-server() {
    pkgdesc='Central web UI for next-update agents: status, holds, manual updates'
    depends=('python' 'systemd')
    backup=('etc/next-update-server/config')

    install -Dm755 next-update-server "$pkgdir/usr/bin/next-update-server"
    install -Dm644 next-update-server.service "$pkgdir/usr/lib/systemd/system/next-update-server.service"
    install -Dm600 next-update-server.conf "$pkgdir/etc/next-update-server/config"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
