#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import csv


def process_trading212(filepath):
    with open(filepath, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            print(row)


def load_file(files_path):
    for filename in os.listdir(files_path):
        if filename.endswith(".trading212"):
            process_trading212(os.path.join(files_path, filename))


def main():
    files_path = "Files"
    load_file(files_path)


if __name__ == '__main__':
    main()
