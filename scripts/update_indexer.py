import json
import os

def copy_nile_deployment_config():
    # Copy goerli.deployments.txt contracts to front end
    d = {}
    with open('goerli.deployments.txt', 'r') as nile_file:
        for line in nile_file:
            d[line.split(':')[2].strip()] = line.split(':')[0]

    x = { 
    "networks": 
        { "goerli": 
            d
        } 
    }
    with open("../../guildly/apibara/python-indexer-template/deployments-config.json", "w") as deployments_config_json:
        json.dump(x, deployments_config_json)

    os.remove('goerli.deployments.txt')
    print("Front end JSON updated!")

def main():
    copy_nile_deployment_config()

if __name__ == "__main__":
    main()