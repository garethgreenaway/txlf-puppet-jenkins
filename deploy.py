#!/usr/bin/env python

import getopt, re, sys

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "he:t:a:r:f:b:c:", ["help", "environment=", "type=", "branch=", "revision=", "frontend=", "backen
d=", "region="])

    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        sys.exit(2)

    revision = None
    region = ""
    frontend = True
    backend = True
    svn_type = None
    branch = None

    for o, a in opts:
        if o == "-v":
            verbose = True

        elif o in ("-h", "--help"):
            usage()
            sys.exit()

        elif o in ("-e", "--environment"):
            environment = a

        elif o in ("-t", "--type"):
            svn_type = a

        elif o in ("-a", "--branch"):
            branch = a

        elif o in ("-c", "--region"):
            region = a

        elif o in ("-r", "--revision"):
            revision = a

        elif o in ("-f", "--frontend"):
            if a == "true":
                frontend = True
            else:
                frontend = False

        elif o in ("-b", "--backend"):
            if a == "true":
                backend = True
            else:
                backend = False

        else:
            assert False, "unhandled option"

    file = "/etc/puppet/%s/modules/<add company module name here>/manifests/params/%s_deployment.pp" % (environment, environment)
    f = open(file)
    contents = f.readlines()
    f.close()

    f = open(file, 'r+')
    for item in contents:

        if "war_revision = " in item:
            if backend:
                new = re.sub(r'\d+', revision, item)
                item = new

        if "www_revision = " in item:
            if frontend:
                new = re.sub(r'\d+', revision, item)
                item = new

        if "war_svn_type = " in item:
            if svn_type:
                item = "  $war_svn_type = '%s'\n" % (svn_type)

        if "www_svn_type = " in item:
            if svn_type:
                item = "  $www_svn_type = '%s'\n" % (svn_type)

        if "war_branch = " in item:
            if branch:
                item = "  $war_branch = 'Zumbox%s_%s'\n" % (region, branch)
            else:
                item = "  $war_branch = ''\n"

        if "www_branch = " in item:
            if branch:
                item = "  $www_branch = '%s'\n" % (branch)
            else:
                item = "  $www_branch = ''\n"

        f.write(item)
    f.close()

if __name__ == "__main__":
    main()

