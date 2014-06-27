# vagrant vsftp and other tricks
# from: https://ttboj.wordpress.com/2013/12/21/vagrant-vsftp-and-other-tricks/
# and
# Vagrant clustered SSH and 'screen'
# from: https://ttboj.wordpress.com/2014/01/02/vagrant-clustered-ssh-and-screen/
# for use inside a ~/.bashrc or similar
# copyright James Shubin, 2013, agplv.3+

### VAGRANT ###################################################################
# avoid needing to always add --provider=kvm
#export VAGRANT_DEFAULT_PROVIDER=kvm
export VAGRANT_DEFAULT_PROVIDER=libvirt
alias vs='vagrant status'
alias vp='vagrant provision'
alias vup='vagrant up'
alias vssh='vagrant ssh'
alias vdestroy='vagrant destroy'
function vlog {
	VAGRANT_LOG=info vagrant "$@" 2> vagrant.log
}
# vagrant sftp
function vsftp {
	[ "$1" = '' ] || [ "$2" != '' ] && echo "Usage: vsftp <vm-name> - vagrant sftp" 1>&2 && return 1
	wd=`pwd`		# save wd, then find the Vagrant project
	while [ "`pwd`" != '/' ] && [ ! -e "`pwd`/Vagrantfile" ] && [ ! -d "`pwd`/.vagrant/" ]; do
		#echo "pwd is `pwd`"
		cd ..
	done
	pwd=`pwd`
	cd $wd
	if [ ! -e "$pwd/Vagrantfile" ] || [ ! -d "$pwd/.vagrant/" ]; then
		echo 'Vagrant project not found!' 1>&2 && return 2
	fi

	d="$pwd/.ssh"
	f="$d/$1.config"

	# if mtime of $f is > than 5 minutes (5 * 60 seconds), re-generate...
	if [ `date -d "now - $(stat -c '%Y' "$f" 2> /dev/null) seconds" +%s` -gt 300 ]; then
		mkdir -p "$d"
		# we cache the lookup because this command is slow...
		vagrant ssh-config "$1" > "$f" || rm "$f"
	fi
	[ -e "$f" ] && sftp -F "$f" "$1"
}

# vagrant screen
function vscreen {
	[ "$1" = '' ] || [ "$2" != '' ] && echo "Usage: vscreen <vm-name> - vagrant screen" 1>&2 && return 1
	wd=`pwd`		# save wd, then find the Vagrant project
	while [ "`pwd`" != '/' ] && [ ! -e "`pwd`/Vagrantfile" ] && [ ! -d "`pwd`/.vagrant/" ]; do
		#echo "pwd is `pwd`"
		cd ..
	done
	pwd=`pwd`
	cd $wd
	if [ ! -e "$pwd/Vagrantfile" ] || [ ! -d "$pwd/.vagrant/" ]; then
		echo 'Vagrant project not found!' 1>&2 && return 2
	fi

	d="$pwd/.ssh"
	f="$d/$1.config"
	h="$1"
	# hostname extraction from user@host pattern
	p=`expr index "$1" '@'`
	if [ $p -gt 0 ]; then
		let "l = ${#h} - $p"
		h=${h:$p:$l}
	fi

	# if mtime of $f is > than 5 minutes (5 * 60 seconds), re-generate...
	if [ `date -d "now - $(stat -c '%Y' "$f" 2> /dev/null) seconds" +%s` -gt 300 ]; then
		mkdir -p "$d"
		# we cache the lookup because this command is slow...
		vagrant ssh-config "$h" > "$f" || rm "$f"
	fi
	[ -e "$f" ] && ssh -t -F "$f" "$1" 'screen -xRR'
}

# vagrant cssh
function vcssh {
	[ "$1" = '' ] && echo "Usage: vcssh [options] [user@]<vm1>[ [user@]vm2[ [user@]vmN...]] - vagrant cssh" 1>&2 && return 1
	wd=`pwd`		# save wd, then find the Vagrant project
	while [ "`pwd`" != '/' ] && [ ! -e "`pwd`/Vagrantfile" ] && [ ! -d "`pwd`/.vagrant/" ]; do
		#echo "pwd is `pwd`"
		cd ..
	done
	pwd=`pwd`
	cd $wd
	if [ ! -e "$pwd/Vagrantfile" ] || [ ! -d "$pwd/.vagrant/" ]; then
		echo 'Vagrant project not found!' 1>&2 && return 2
	fi

	d="$pwd/.ssh"
	cssh="$d/cssh"
	cmd=''
	cat='cat '
	screen=''
	options=''

	multi='f'
	special=''
	for i in "$@"; do	# loop through the list of hosts and arguments!
		#echo $i

		if [ "$special" = 'debug' ]; then	# optional arg value...
			special=''
			if [ "$1" -ge 0 -o "$1" -le 4 ]; then
				cmd="$cmd $i"
				continue
			fi
		fi

		if [ "$multi" = 'y' ]; then	# get the value of the argument
			multi='n'
			cmd="$cmd '$i'"
			continue
		fi

		if [ "${i:0:1}" = '-' ]; then	# does argument start with: - ?

			# build a --screen option
			if [ "$i" = '--screen' ]; then
				screen=' -o RequestTTY=yes'
				cmd="$cmd --action 'screen -xRR'"
				continue
			fi

			if [ "$i" = '--debug' ]; then
				special='debug'
				cmd="$cmd $i"
				continue
			fi

			if [ "$i" = '--options' ]; then
				options=" $i"
				continue
			fi

			# NOTE: commented-out options are probably not useful...
			# match for key => value argument pairs
			if [ "$i" = '--action' -o "$i" = '-a' ] || \
			[ "$i" = '--autoclose' -o "$i" = '-A' ] || \
			#[ "$i" = '--cluster-file' -o "$i" = '-c' ] || \
			#[ "$i" = '--config-file' -o "$i" = '-C' ] || \
			#[ "$i" = '--evaluate' -o "$i" = '-e' ] || \
			[ "$i" = '--font' -o "$i" = '-f' ] || \
			#[ "$i" = '--master' -o "$i" = '-M' ] || \
			#[ "$i" = '--port' -o "$i" = '-p' ] || \
			#[ "$i" = '--tag-file' -o "$i" = '-c' ] || \
			[ "$i" = '--term-args' -o "$i" = '-t' ] || \
			[ "$i" = '--title' -o "$i" = '-T' ] || \
			[ "$i" = '--username' -o "$i" = '-l' ] ; then
				multi='y'	# loop around to get second part
				cmd="$cmd $i"
				continue
			else			# match single argument flags...
				cmd="$cmd $i"
				continue
			fi
		fi

		f="$d/$i.config"
		h="$i"
		# hostname extraction from user@host pattern
		p=`expr index "$i" '@'`
		if [ $p -gt 0 ]; then
			let "l = ${#h} - $p"
			h=${h:$p:$l}
		fi

		# if mtime of $f is > than 5 minutes (5 * 60 seconds), re-generate...
		if [ `date -d "now - $(stat -c '%Y' "$f" 2> /dev/null) seconds" +%s` -gt 300 ]; then
			mkdir -p "$d"
			# we cache the lookup because this command is slow...
			vagrant ssh-config "$h" > "$f" || rm "$f"
		fi

		if [ -e "$f" ]; then
			cmd="$cmd $i"
			cat="$cat $f"	# append config file to list
		fi
	done

	cat="$cat > $cssh"
	#echo $cat
	eval "$cat"			# generate combined config file

	#echo $cmd && return 1
	#[ -e "$cssh" ] && cssh --options "-F ${cssh}$options" $cmd
	# running: bash -c glues together --action 'foo --bar' type commands...
	[ -e "$cssh" ] && bash -c "cssh --options '-F ${cssh}${screen}$options' $cmd"
}
