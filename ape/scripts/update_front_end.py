import yaml
import json

def update_front_end_json():

    # Converting the brownie config into JSON format
    with open("ape-config.yaml", "r") as ape_config:
        config_dict = yaml.load(ape_config, Loader=yaml.FullLoader)
        with open("./front_end/ape-config.json", "w") as ape_config_json:
            json.dump(config_dict, ape_config_json)
    print("Front end JSON updated!")

def main():
    update_front_end_json()