from web3 import Web3, HTTPProvider
from web3.main import get_default_modules

""" 
连接到以太坊某个节点的链接，一般用户连接以太坊，会从infura.io获取一个自己独有的专门的链接。
具体获取步骤：
1、访问https://infura.io，注册并登录
2、点击'CREATE NEW PROJECT'新建一个项目，之后点击新建的项目上的'SETTING'按钮    # 对项目进行配置，而不是对整个infura。
3、找到KEYS -> ENDPOINTS，拷贝任意ENDPOINTS链接
"""
uri = 'https://mainnet.infura.io/v3/e15f0589fa624c27a01cdaf6a2838773'
web3 = Web3(HTTPProvider())
print(get_default_modules())    # web3默认支持的rpc模块

# 示例：查询区块号
print(web3.eth.block_number())

# 示例：查询合约地址上的代码
print(web3.eth.get_code(''))    # 填入合约地址


##################
# 示例：部署合约  #
##################

address = ''    # 用于部署合约的以太坊账户地址
private_key = ''

# 以下abi、bytecode内容，建议使用vscode，安装solidity插件，在打开合约文件后，右键'solidity: compile contract'生成。
abi = []    # 合约的编译生成的'.abi'文件内容，是合约的接口描述信息
bytecode = ''    # 合约的编译生成的'.bin'文件内容，是合约二进制的hex形式内容

contract = web3.eth.contract(abi=abi, bytecode=bytecode)

base_txn = {
    "gasPrice": web3.eth.gas_price,     # 这里使用链上推荐的gas_price
    "gas": 1000000,                     # 部署合约可接受的gas消耗上限，合约代码可以指定多退或不退。建议通过estimate_gas接口预进行估，后续有示例。
    "nonce": web3.eth.get_transaction_count(address),
    "chainId": web3.eth.chain_id,       # chain_id，用于避免区块链交易重放攻击。
    "value": 0,                         # 在合约初始化时，转给合约地址的钱，请慎用，一般为0即可。
    "data": '',  # 编码后的合约内容，当前留空或删除
}

"""
重要：
编码生成合约data，生成带data的txn。
如果合约存在constructor方法，则填入初始化参数，否则留空。
初始化参数建议以关键字方式传入。
"""
txn = contract.constructor(kwarg='请填入初始化参数').buildTransaction(base_txn)

# 预估gas的示例，请在生成合约data后再调用，可以用此gas替换txn中硬编码的gas
# gas = web3.eth.estimate_gas(txn)

# 以下为签名


