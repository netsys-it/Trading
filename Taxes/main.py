#!/usr/bin/python
# -*- coding: utf-8 -*-
import datetime
import os
import csv


def process_trading212(filepath):
    """
    Function to parse csv export from https://www.trading212.com/
    Tax law for Slovakia https://www.zakonypreludi.sk/zz/2003-595
    :param filepath: Export file path.
    :return:
    """
    tax_year = int(input("Enter year for TAX: "))
    with open(filepath, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        dividend_amount = 0
        dividend_witholding_tax = 0
        deposit_amount = 0
        total_profit = 0
        total_loss = 0
        total_fees = 0
        for row in reader:
            transaction_date = datetime.datetime.strptime(row['Time'], '%Y-%m-%d %H:%M:%S')
            if transaction_date.year == tax_year:
                if row['Action'] == 'Dividend (Ordinary)':
                    dividend_amount += float(row['Total (EUR)'])
                    dividend_witholding_tax += float(row['Withholding tax'])
                if row['Action'] == 'Deposit':
                    deposit_amount += float(row['Total (EUR)'])
                if row['Action'] == 'Market buy':
                    if row['Currency conversion fee (EUR)']:
                        total_fees += float(row['Currency conversion fee (EUR)'])
                if row['Action'] == 'Market sell':
                    if float(row['Result (EUR)']) < 0:
                        total_loss -= float(row['Result (EUR)'])
                    else:
                        total_profit += float(row['Result (EUR)'])
                    if row['Currency conversion fee (EUR)']:
                        total_fees += float(row['Currency conversion fee (EUR)'])
        print("\tTotal Deposit:\t\t\t\t\t\t{:.2f} (EUR)".format(deposit_amount))
        print("\tTotal Dividends:\t\t\t\t\t{:.2f} (EUR)".format(dividend_amount))
        print("\tTotal Dividends Withholding tax:\t{:.2f} (USD)".format(dividend_amount))
        print("\tTotal Profit:\t\t\t\t\t\t{:.2f} (EUR)".format(total_profit))
        print("\tTotal Loss:\t\t\t\t\t\t\t-{:.2f} (EUR)".format(total_loss))
        print("\tTotal Profit wihtout Loss:\t\t\t{:.2f} (EUR)".format(total_profit - total_loss))
        print("\tTotal FX Fee:\t\t\t\t\t\t{:.2f} (EUR)".format(total_fees))
        print("\t------------------------------------------------")
        print("\tTotal Income:\t\t\t\t\t\t{:.2f} (EUR)".format(total_profit))
        print("\tTotal Outcome:\t\t\t\t\t\t{:.2f} (EUR)".format(abs(total_loss) + total_fees))


def load_file(files_path):
    for filename in os.listdir(files_path):
        if filename.endswith(".trading212"):
            process_trading212(os.path.join(files_path, filename))


def main():
    files_path = "Files"
    load_file(files_path)


if __name__ == '__main__':
    main()
