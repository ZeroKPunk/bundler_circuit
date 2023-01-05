import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'

const config: HardhatUserConfig = {
  solidity: "0.8.12",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    dev: { 
      url: 'http://localhost:7545',
      blockGasLimit: 900000000429720 // whatever you want here

    }
    
  },
  
};

export default config;
