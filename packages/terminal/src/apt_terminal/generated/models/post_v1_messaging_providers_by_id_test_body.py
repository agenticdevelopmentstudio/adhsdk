from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MessagingProvidersByIdTestBody")


@_attrs_define
class PostV1MessagingProvidersByIdTestBody:
    """
    Attributes:
        to (str | Unset): Email address or phone number to send the test to
    """

    to: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        to = self.to

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if to is not UNSET:
            field_dict["to"] = to

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        to = d.pop("to", UNSET)

        post_v1_messaging_providers_by_id_test_body = cls(
            to=to,
        )

        return post_v1_messaging_providers_by_id_test_body
