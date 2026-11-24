from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetVersionResponse200")


@_attrs_define
class GetVersionResponse200:
    """
    Attributes:
        name (str):
        version (str):
        region (str):
    """

    name: str
    version: str
    region: str

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        version = self.version

        region = self.region

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
                "version": version,
                "region": region,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        version = d.pop("version")

        region = d.pop("region")

        get_version_response_200 = cls(
            name=name,
            version=version,
            region=region,
        )

        return get_version_response_200
