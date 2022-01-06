#!/usr/bin/python
# -*- coding: utf-8 -*-
import datetime
import os
import csv


def process_trading212(filepath):
    tax_year = int(input("Enter year for TAX: "))
    with open(filepath, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        dividend_amount = 0
        dividend_witholding_tax = 0
        deposit_amount = 0
        row_ids = list()
        for row in reader:
            transaction_date = datetime.datetime.strptime(row['Time'], '%Y-%m-%d %H:%M:%S')
            if transaction_date.year == tax_year:
                if row['Action'] == 'Dividend (Ordinary)':
                    dividend_amount += float(row['Total (EUR)'])
                    dividend_witholding_tax += float(row['Withholding tax'])
                if row['Action'] == 'Deposit':
                    deposit_amount += float(row['Total (EUR)'])
                if row['Action'] == 'Market buy':
                    pass
                if row['Action'] == 'Market sell':
                    pass
        print(f"Total Deposit in {tax_year} was {deposit_amount} (EUR)")
        print(f"Total Dividends in {tax_year} was {dividend_amount} (EUR)")
        print(f"Total Dividends Withholding tax in {tax_year} was {dividend_amount} (USD)")


def load_file(files_path):
    for filename in os.listdir(files_path):
        if filename.endswith(".trading212"):
            process_trading212(os.path.join(files_path, filename))


def main():
    files_path = "Files"
    load_file(files_path)


if __name__ == '__main__':
    main()
