#!/bin/bash 

pc_path=$(dirname $(realpath "$(dirname $0)"))              # path/to/pc/top/directory/kan-fpga

sudo apt-get update
sudo apt-get install -y iverilog graphviz graphviz-dev

cd $pc_path
git submodule update --init

if [ ! -d "venv/bin" ]; then
    python3 -m venv venv
fi

source venv/bin/activate

pip install -r venv/requirements.txt