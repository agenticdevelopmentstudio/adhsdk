from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="SupportLinkApprove")


@_attrs_define
class SupportLinkApprove:
    """
    Attributes:
        token (str): The email link's token.
        code (str): The code emailed by `approve/code`.
    """

    token: str
    code: str

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        code = self.code

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "token": token,
                "code": code,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        code = d.pop("code")

        support_link_approve = cls(
            token=token,
            code=code,
        )

        return support_link_approve
