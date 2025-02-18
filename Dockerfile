FROM public.ecr.aws/lambda/python:3.12

# Write Docker commands to package your Python application with its dependencies
# so that it can

# tips: a python 'requirements.txt' file to insall the Python dependencies with pip
# can be generated using 'poetry export --without-hashes > lambda_app/requirements.txt'
# before building the image with 'docker build ...'

RUN ...

# Set CMD so that the entry point of the lambda is the 'lambda_handler' function.
CMD ...
