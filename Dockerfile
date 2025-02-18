FROM public.ecr.aws/lambda/python:3.12

WORKDIR /var/task


COPY lambda_app lambda_app
COPY pyproject.toml poetry.lock ./

RUN pip install --no-cache-dir poetry==1.8.3
RUN poetry export --without-hashes -o lambda_app/requirements.txt

# no-cache-dir is used to avoid caching the index and wheels
RUN pip install --no-cache-dir -r lambda_app/requirements.txt

CMD ["lambda_app.app.lambda_handler"]


# Write Docker commands to package your Python application with its dependencies
# so that it can

# tips: a python 'requirements.txt' file to insall the Python dependencies with pip
# can be generated using 'poetry export --without-hashes > lambda_app/requirements.txt'
# before building the image with 'docker build ...'
