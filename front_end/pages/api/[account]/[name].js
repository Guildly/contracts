import fs from "fs";
import { Provider } from 'starknet';
import { stringToFelt } from "../../../utils/felt";
import { json } from "starknet";

export default function handler(req, res) {

  const { account, name } = req.query;
  const readContract = (name) => json.parse(fs.readFileSync(`./${name}.json`).toString('ascii'));

  const provider = new Provider({
    baseUrl: 'https://hackathon-2.starknet.io',
    feederGatewayUrl: 'feeder_gateway',
    gatewayUrl: 'gateway',
  })

  const callData = ["0x1", account, "0x0", "0x0", "0x00042874e73c9f80f48be03b3b358df8f479f5b81594a5397565c7417aa42c93", stringToFelt(name)];
  provider.deployContract({
    contract: readContract("contracts/Guilds"),
    constructorCalldata: callData
  }).then(
    function (value) {
      res.status(200).json(value)
    },
    function (error) { res.status(200).json(error) }
  );

}
