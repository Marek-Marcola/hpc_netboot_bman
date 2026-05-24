netboot bman
============

Netboot management tools.

Install
-------
Install:

    ./bman.sh --install
    -- or --
    cp -fv bman.env /usr/local/etc
    cp -fv bman.sh /usr/local/bin

Postinstall:

    # cat > /etc/profile.d/zlocal-bman.sh <<\EOF
    bm() {
      local desc="@@boot management (via bman.sh)@@"
      bman.sh $@
    }
    EOF

Verify:

    bman.sh --version

Help:

    bman.sh --help
