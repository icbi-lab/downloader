#!/usr/bin/env python
import argparse
import os
import sys

import requests
import json

__author__      = "Dietmar Rieder"
__copyright__   = "Copyright 2020, ICBI"
__credits__     = ["Dietmar Rieder"]
__license__     = "GPL"
__version__     = "1.0.0"
__maintainer__  = "Dietmar Rieder"
__email__       = "dietmar.rieder@i-med.ac.at"
__status__      = "Production"


def get_slice(gdcfile_uuid, slice_type, slice_req, outfile, token_file):
    data_endpt = "https://api.gdc.cancer.gov/slicing/view/{}".format(gdcfile_uuid)
    with open(token_file, "r") as token:
        token_string = str(token.read().strip())

        if slice_type == "gene":
            params = {"gencode": slice_req}
        elif slice_type == "region":
            params = {"region": slice_req}

        response = requests.post(
            data_endpt,
            data=json.dumps(params),
            headers={"Content-Type": "application/json", "X-Auth-Token": token_string},
        )

        outfile.write(response.content)


if __name__ == "__main__":
    # usage = __doc__.split("\n\n\n")
    parser = argparse.ArgumentParser(
        description="Download BAM slices from gdc"
    )


    def _file_write(fname):
        """Returns an open file handle if the given filename exists."""
        return open(fname, "wb")


    def _mk_slice(slice_in):
        """Returns a list of slices."""
        return slice_in.split(",")


    parser.add_argument("--gdc_file_uuid", required=True, type=str, help="BAM file UUID")
    parser.add_argument(
        "--slice_type",
        required=True,
        type=str,
        choices=["gene", "region"],
        help="Get region or gene",
    )
    parser.add_argument(
        "--slice_req",
        required=True,
        type=_mk_slice,
        help="slice: genes or regions comma separated",
    )
    parser.add_argument(
        "--outfile", required=True, type=_file_write, help="slice BAM file out"
    )
    parser.add_argument(
        "--token_file", required=True, type=str, help="GDC token file"
    )

    args = parser.parse_args()

    get_slice(args.gdc_file_uuid, args.slice_type, args.slice_req, args.outfile, args.token_file)

