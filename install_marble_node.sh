#!/bin/bash

ENV_SETUP=0

function isInstalled {
  return_=1
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}


function echo_pass {
  # echo first argument in green
  printf "${1}		\e[32m✔"
  # reset colours back to normal
  printf "\033\e[0m"
  printf "\n"
}


function echo_if {
  if [ $1 == 1 ]; then
    echo_pass "$2"
  else
    echo_fail "$2"
  fi
}

function echo_fail {
  # echo first argument in red
  printf "${1}		\e[31m✘ \033\e[0m	${2}"
  # reset colours back to normal
  printf "\033\e[0m"
  printf "\n"
  ENV_SETUP=1
}

function checkEnvSetup {
	printf "\n\e[32m##### Check Env Setup for Mables ##### \033\e[0m \n"
	if [ $(isInstalled node) == 1 ]; then
		echo_pass 'node'
	else
		echo_fail 'node'
	fi


	if [ $(isInstalled git) == 1 ]; then
		echo_pass 'git'
	else
		echo_fail 'git'
	fi


	if [ $(isInstalled go) == 1 ]; then
		echo_pass 'go'
	else
		echo_fail 'go'
	fi


	if [ $(isInstalled docker) == 1 ]; then
		echo_pass 'docker'
	else
		echo_fail 'docker'
	fi

	if [ $ENV_SETUP == 1 ]; then
		printf "\n\e[31mPlease install recommended tools \033\e[0m \n"
		printf "= node : v6.2+ or v8.1+(recommend), install from 'curl -L https://git.io/n-install | bash' \n"
		printf "= go : v1.7.0+,  download from https://golang.org/dl \n"
		printf "= docker : v1.13+ Install from 'curl -fsSL https://get.docker.com/ | sudo sh' \n\t(if Mac, Download from https://docs.docker.com/docker-for-mac)\n"
		printf "= docker-compose : v1.8+ Install from 'curl -fsSL https://get.docker.com/ | sudo sh' \n\t(if Mac, Download from https://docs.docker.com/docker-for-mac)\n"
		printf "\e[32m############## END ################### \033\e[0m \n"

		exit 1	
	else
		printf "\e[32m############## END ################### \033\e[0m \n"	
	fi
}

export BEZANT_HOME=~/bezantdev/

function printTitle {
	printf "\n\e[32m${1} \033\e[0m \n"	
}

function installMarbles {
	printTitle "# Download marbles from git.."
	mkdir $BEZANT_HOME
	cd $BEZANT_HOME

	echo "git clone https://github.com/IBM-Blockchain/marbles.git --depth 1"	
	git clone https://github.com/IBM-Blockchain/marbles.git --depth 1
	cd marbles
}

function installFabricDependeciesWithRoot {
	printTitle "# Find dependencies with permission.."
	LOG_HOME_PATH="$HOME/.npm/_logs"
	LOG_FILE_NAME=`ls -tr $LOG_HOME_PATH | tail -1`
	FAIL_ITEM_LIST=`cat $LOG_HOME_PATH/$LOG_FILE_NAME | grep Failed | grep "@" | awk -F'@' '{print $1}' | awk '{print $NF}' | sort | uniq`

	printTitle "# Install dependencies with permission.."
	IFS=$'\n' # make newlines the only separator
	for j in $FAIL_ITEM_LIST
	do
		echo "sudo npm install $j --unsafe-perm=true --allow-root"
		sudo npm install $j --unsafe-perm=true --allow-root
	done
}


function installFabricSample {
	printTitle "# Download FabricSample from git.."
	echo "git clone https://github.com/hyperledger/fabric-samples.git"	
	git clone https://github.com/hyperledger/fabric-samples.git
	cd fabric-sample

	printTitle "# Download the docker images of the various fabric components"
	curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/release-1.1/scripts/bootstrap-1.1.0-preview.sh -o setup_script.sh
	printTitle "# Execute download script"
	sudo sudo bash setup_script.sh

	printTitle "# Add Fabric binaries to your PATH"
	export PATH=$PWD/bin:$PATH

	printTitle "# Start fabric network..."
	cd $BEZANT_HOME/marbles/fabric-samples/fabcar; 
	sudo ./startFabric.sh
	echo $PWD
	echo $PATH

	printTitle "# Install node.js dependencies for the fabcar sample.."
	sudo npm install
	
	RETVAL=$?	
	echo $RETVAL	
	if [ $RETVAL -ne 0 ]
    	then
		installFabricDependeciesWithRoot

		printTitle "# RE-Install node.js dependencies for the fabcar sample.."
        	sudo npm install
		RETVAL=$?
		echo "######################## $RETVAL"
    	fi
}

function installAndInstantiateCC {
	cd $BEZANT_HOME/marbles/fabric-samples/fabcar
	
	printTitle "Enroll and Register User.."
	node enrollAdmin.js
	node registerUser.js

	CNT_PF_LOCAL="$BEZANT_HOME/marbles/config/connection_profile_local.json"
	printTitle "Reflect your ENV to $CNT_PF_LOCAL file.."
	sed -i "" 's/$HOME/Users\/jeyce\/bezantdev\/marbles/g' $CNT_PF_LOCAL

	cd $BEZANT_HOME/marbles/scripts
	npm install
	node install_chaincode.js
	node instantiate_chaincode.js

	cp $BEZANT_HOME/marbles/fabric-samples/fabcar/hfc-key-store/*-priv ~/.hfc-key-store
}

function installMarblesApp {

	printTitle "Install Marbles.."
	cd $BEZANT_HOME/marbles
	npm install gulp -g
	npm install


	printTitle "Run Marbles.."
	gulp marbles_local

	printTitle "Install completely.."
}

function initDocker {
#docker rm $(docker stop $(docker image list | egrep "hyperle|peer0" | awk '{print $3}'))
#docker rmi $(docker stop $(docker image list | egrep "hyperle|peer0" | awk '{print $3}'))
	docker stop $(docker ps -aq)
	docker image prune -a
}


checkEnvSetup
installMarbles
installFabricSample
installAndInstantiateCC
installMarblesApp


## check go
#if ! type "node" > /dev/null; then
#  # install foobar here
#
#echo "aa"
#fi
#
## check git
#if ! type "node" > /dev/null; then
#  # install foobar here
#echo "aa"
#fi
#
## check node
#if ! type "node" > /dev/null; then
#  # install foobar here
#echo "aa"
#fi
#



