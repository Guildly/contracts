import json

api_key = "966aba275f4e35f13eb2"
api_key = "ec4819a74e885505a0d14dcc61bdcbdc65e5c75a18e35dded12bac075c360eef"
jwt_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIyOTg5NGM3Ny03NzQ3LTQ5YzQtYjIyMy1hMjI2MzY0NTEwNDEiLCJlbWFpbCI6InNhbS5qLnBlZWtAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siaWQiOiJGUkExIiwiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjF9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZX0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6Ijk2NmFiYTI3NWY0ZTM1ZjEzZWIyIiwic2NvcGVkS2V5U2VjcmV0IjoiZWM0ODE5YTc0ZTg4NTUwNWEwZDE0ZGNjNjFiZGNiZGM2NWU1Yzc1YTE4ZTM1ZGRlZDEyYmFjMDc1YzM2MGVlZiIsImlhdCI6MTY1MjgwMjE1NX0.wi4RP3fS1nhzvPzR-R_zc00lIA7pRXsqFxuoMY3qDiY"

IMAGES_BASE_URL = "https://gateway.pinata.cloud/ipfs/"
PROJECT_NAME = "GAME_GUILDS"

token = {
    "image": IMAGES_BASE_URL + str(token_id) + '.png',
    "tokenId": token_id,
    "name": PROJECT_NAME + ' ' + str(token_id),
    "attributes": []
}

with open('./metadata/' + str(token_id) + ".json", 'w') as outfile:
    json.dump(token, outfile, indent=4)