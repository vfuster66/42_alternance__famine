#!/usr/bin/env python3
"""
Script pour calculer le hash d'un hostname
Utilisé pour configurer le déclenchement conditionnel de Famine
"""

import sys


def calculate_hash(hostname):
    """Calcule le hash d'une chaîne """
    """(algorithme identique à celui d'assemblage)"""
    hash_val = 0
    for char in hostname:
        hash_val = hash_val * 31 + ord(char)
        # Garder seulement les 64 bits pour éviter le débordement
        hash_val = hash_val & 0xFFFFFFFFFFFFFFFF
    return hash_val


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 calculate_hash.py <hostname>")
        print("Example: python3 calculate_hash.py $(hostname)")
        sys.exit(1)

    hostname = sys.argv[1]
    hash_val = calculate_hash(hostname)

    print(f"Hostname: {hostname}")
    print(f"Hash: 0x{hash_val:016X}")
    print(f"Hash (decimal): {hash_val}")
    print()
    print("Pour utiliser ce hash dans control.asm, remplacez:")
    print("    .hostname_hash:     dq 0x123456789ABCDEF0")
    print("par:")
    print(f"    .hostname_hash:     dq 0x{hash_val:016X}")


if __name__ == '__main__':
    main()
