from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="AdminSitePut")


@_attrs_define
class AdminSitePut:
    """
    Attributes:
        host (str): A DNS name with at least two labels; no scheme, port or path.
    """

    host: str

    def to_dict(self) -> dict[str, Any]:
        host = self.host

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "host": host,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        host = d.pop("host")

        admin_site_put = cls(
            host=host,
        )

        return admin_site_put
