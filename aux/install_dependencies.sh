sudo apt-get install -y iverilog graphviz graphviz-dev

pc_path=$(dirname $(realpath "$(dirname $0)"))              # path/to/pc/top/directory/kan-fpga

cd $pc_path

source venv/bin/activate

pip install -r venv/requirements.txt