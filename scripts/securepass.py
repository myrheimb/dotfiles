#!/usr/bin/env python3
"""Secure password generator."""

import argparse
import random
import secrets
import string
import sys
import typing as t

AMBIGUOUS_CHARS = "l1Io0O"
SPECIAL_CHARS_STR = "!?#@.-_+=*^><"

LOWERCASE_CHARS = list(string.ascii_lowercase)
UPPERCASE_CHARS = list(string.ascii_uppercase)
DIGITS = list(string.digits)
SPECIAL_CHARS = list(SPECIAL_CHARS_STR)

crypto_random = random.SystemRandom()


def generate_password(
    length: int,
    use_lowercase: bool,
    use_uppercase: bool,
    use_digits: bool,
    use_special: bool,
    exclude_ambiguous: bool,
) -> str:
    """Generate a single secure password."""
    char_groups: t.List[t.List[str]] = []
    if use_lowercase:
        char_groups.append(LOWERCASE_CHARS)
    if use_uppercase:
        char_groups.append(UPPERCASE_CHARS)
    if use_digits:
        char_groups.append(DIGITS)
    if use_special:
        char_groups.append(SPECIAL_CHARS)

    if not char_groups:
        raise ValueError(
            "At least one character type must be selected to generate a password."
        )

    if exclude_ambiguous:
        char_groups = [
            [char for char in group if char not in AMBIGUOUS_CHARS]
            for group in char_groups
        ]
        # Remove any groups that became empty after removing ambiguous characters
        char_groups = [group for group in char_groups if group]

    if not char_groups:
        raise ValueError(
            "The character set is empty, likely because all selected character types "
            "contained only ambiguous characters which were excluded."
        )

    if length < len(char_groups):
        raise ValueError(
            f"Password length must be at least {len(char_groups)} to include "
            "one character from each selected type."
        )

    # Guarantee at least one character from each required group.
    password_chars = [secrets.choice(group) for group in char_groups]

    # Create the full character pool for the remaining characters.
    full_char_pool = [char for group in char_groups for char in group]

    # Fill the rest of the password length.
    for _ in range(length - len(password_chars)):
        password_chars.append(secrets.choice(full_char_pool))

    # Shuffle the characters to ensure randomness.
    # We use SystemRandom for a cryptographically secure shuffle.
    crypto_random.shuffle(password_chars)

    return "".join(password_chars)


def main():
    """Parse arguments and generate passwords."""
    parser = argparse.ArgumentParser(
        description="Generate one or more secure passwords.",
    )
    parser.add_argument("length", type=int, help="The length of the password(s).")
    parser.add_argument(
        "-c",
        "--count",
        type=int,
        default=1,
        help="The number of passwords to generate.",
    )

    # Character group toggles
    parser.add_argument(
        "--no-lowercase",
        dest="use_lowercase",
        action="store_false",
        help="Exclude lowercase letters from the password.",
    )
    parser.add_argument(
        "--no-uppercase",
        dest="use_uppercase",
        action="store_false",
        help="Exclude uppercase letters from the password.",
    )
    parser.add_argument(
        "--no-digits",
        dest="use_digits",
        action="store_false",
        help="Exclude digits from the password.",
    )
    parser.add_argument(
        "--no-special",
        dest="use_special",
        action="store_false",
        help="Exclude special characters from the password.",
    )
    parser.add_argument(
        "--exclude-ambiguous",
        dest="exclude_ambiguous",
        action="store_true",
        help=f"Exclude ambiguous characters: {AMBIGUOUS_CHARS}",
    )

    parser.set_defaults(
        use_lowercase=True,
        use_uppercase=True,
        use_digits=True,
        use_special=True,
        exclude_ambiguous=False,
    )

    args = parser.parse_args()

    try:
        if args.length <= 0:
            raise ValueError("Password length must be a positive integer.")

        for _ in range(args.count):
            password = generate_password(
                length=args.length,
                use_lowercase=args.use_lowercase,
                use_uppercase=args.use_uppercase,
                use_digits=args.use_digits,
                use_special=args.use_special,
                exclude_ambiguous=args.exclude_ambiguous,
            )
            print(password)  # noqa: T201
    except ValueError as e:
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
