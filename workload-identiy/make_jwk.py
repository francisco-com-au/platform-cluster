import json
import base64
import hashlib
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from cryptography.hazmat.primitives.asymmetric import rsa

# Load the RSA public key
with open("generated/sa.pub", "rb") as pub_file:
    public_key = pub_file.read()

# Parse the public key
key = load_pem_public_key(public_key)

# Get the public key in DER (ASN.1) format
public_key_der = key.public_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)

# Compute the SHA-256 hash
sha256_hash = hashlib.sha256(public_key_der).digest()

# Generate the `kid` (first 128 bits of the hash, base64 URL encoded)
kid = base64.urlsafe_b64encode(sha256_hash[:32]).rstrip(b'=').decode("ascii")

# Generate the `n` and `e` (modulus and exponent) in base64 URL-encoded format
if isinstance(key.public_numbers(), rsa.RSAPublicNumbers):
    public_numbers = key.public_numbers()
    n = base64.urlsafe_b64encode(public_numbers.n.to_bytes((public_numbers.n.bit_length() + 7) // 8, "big")).rstrip(b'=').decode("ascii")
    e = base64.urlsafe_b64encode(public_numbers.e.to_bytes((public_numbers.e.bit_length() + 7) // 8, "big")).rstrip(b'=').decode("ascii")

# Create the JWKS
jwks = {
    "keys": [
        {
            "use": "sig",
            "kty": "RSA",
            "alg": "RS256",
            "kid": kid,
            "n": n,
            "e": e
        }
    ]
}

# Save the JWKS to a file
with open("generated/jwk.json", "w") as jwks_file:
    json.dump(jwks, jwks_file, indent=4)
