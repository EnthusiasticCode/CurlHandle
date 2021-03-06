Building libraries

CURLHandle uses its own builds of libcurl, libcares, libcrypto, libssl and libssh2.

The good news is that we commit built versions of these to either this git repo or one of the submodule repos.

So in normal use, you shouldn't need to worry about this, and can stop reading now.

However, should you find yourself needing to rebuild these libraries for some reason, this is how you do it.


## Install Tools

Homebrew
	brew update
	brew install automake (if it's not already installed)
	brew versions automake (we want to use ver. 1.12.6)
	cd /usr/local/Library/Formula/
	git checkout 3a7567c /usr/local/Library/Formula/automake.rb
	brew unlink automake
	brew install automake (should show ver 1.12.6 installing)
	(also note the cool beer mug emoji when brew is done :-P )

    brew install pkg-config
    brew install libtool

There is a script {{Scripts/install-tools.sh}} which you can run to perform these steps.


## Fetch Code

git
	git checkout "v4.x-beta"
	git submodule update --recursive
		(new commits in CurlHandle and SFTP leave the library build dirs in place to allow debugging)

## Build
		 
### Using Xcode
	OpenSSL - libcrypto, libssl
		open SFTP/OpenSSL.xcodeproj
		build target openssl   (with Product / Build For / Archiving)
	libssh2
		open SFTP/libssh2.xcodeproj
		build target libssh2   (for archiving)
	libcurl, libcares
		open CURLHandleSource/CURLHandle.xcodeproj
		build target libcurl   (for archiving)

### From the command line

    cd <the root of the project>
    Scripts/build-libs.sh

## Debugging

Because of the vaguaries of the way these libraries are built, Xcode has trouble locating the source files when you're debugging, even though we do commit the dSYM files.

This is one reason why you might find yourself wanting to build the libraries locally - as long as the built objects etc are hanging around on your machine, Xcode should find the source ok.

Ideally we'll figure out how to fix things so that this isn't necessary.

On the other hand, ideally you won't need to debug the internals of these libraries.
