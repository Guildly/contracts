import yaml
import json
import os
import shutil

# def update_front_end_json():

#     # Converting the brownie config into JSON format
#     with open("ape-config.yaml", "r") as ape_config:
#         config_dict = yaml.load(ape_config, Loader=yaml.FullLoader)
#         with open("./front_end/ape-config.json", "w") as ape_config_json:
#             json.dump(config_dict, ape_config_json)
#     print("Front end JSON updated!")

def update_abis():
    # Copying artifacts abis into front_end folder
    abis_folder = os.path.abspath("artifacts/abis")
    destination_folder = os.path.abspath("../game_guilds_front_end/contracts/abi")
    for file_name in os.listdir(abis_folder):
        source = abis_folder + "/" + file_name
        destination = destination_folder + "/" + file_name
        if os.path.isfile(source):
            shutil.copy(source, destination)
            print('copied', file_name)

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
    with open("../game_guilds_front_end/deployments-config.json", "w") as deployments_config_json:
        json.dump(x, deployments_config_json)

    print("Front end JSON updated!")



def main():
    update_abis()
    copy_nile_deployment_config()

if __name__ == "__main__":
    main()