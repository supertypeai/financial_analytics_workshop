import os
import argparse
import requests 

SECTORS_API_KEY = os.getenv("SECTORS_API_KEY")

def get_company_overview(stock:str, section='overview')->str:

    # assert section is one of overview, valuation, future, peers, financials, dividend, management, ownership
    assert section in ['overview', 'valuation', 'future', 'peers', 'financials', 'dividend', 'management', 'ownership'], "Invalid section"

    url = f"https://api.sectors.app/v1/company/report/{stock}/?sections={section}"
    headers = {"Authorization": SECTORS_API_KEY}

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)

    return data

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Get company overview from stock symbol")
    parser.add_argument("-s", "--stock", type=str, help="Stock symbol to retrieve company overview for.", required=True)
    parser.add_argument("-sec", "--section", type=str, help="Section of company overview to retrieve.", default='overview')
    # optionally prettify it?
    parser.add_argument("--pretty", action='store_true', help="Prettify the output?", default=False)
    args = parser.parse_args()
    result = get_company_overview(args.stock, args.section)
    if(args.pretty):
        import pprint
        pprint.pprint(result)
    else:
        print(result)

