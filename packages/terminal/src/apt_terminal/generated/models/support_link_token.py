from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="SupportLinkToken")


@_attrs_define
class SupportLinkToken:
    """
    Attributes:
        token (str): The email link's token.
    """

    token: str

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "token": token,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        support_link_token = cls(
            token=token,
        )

        return support_link_token
