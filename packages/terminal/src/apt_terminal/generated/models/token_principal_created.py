from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="TokenPrincipalCreated")


@_attrs_define
class TokenPrincipalCreated:
    """
    Attributes:
        id (str):
        rdid (str): reverse-domain id, e.g. token.<owner-slug>.<name>
        slug (str):
        description (str):
        prefix (str): Non-secret leading chars of the secret, for display
        bucket_rdid (str): the token’s own isolated bucket, e.g. storage.<owner-slug>.<name>
        token (str): the raw `adh_…` secret — shown once, never again
    """

    id: str
    rdid: str
    slug: str
    description: str
    prefix: str
    bucket_rdid: str
    token: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        rdid = self.rdid

        slug = self.slug

        description = self.description

        prefix = self.prefix

        bucket_rdid = self.bucket_rdid

        token = self.token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "rdid": rdid,
                "slug": slug,
                "description": description,
                "prefix": prefix,
                "bucket_rdid": bucket_rdid,
                "token": token,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        rdid = d.pop("rdid")

        slug = d.pop("slug")

        description = d.pop("description")

        prefix = d.pop("prefix")

        bucket_rdid = d.pop("bucket_rdid")

        token = d.pop("token")

        token_principal_created = cls(
            id=id,
            rdid=rdid,
            slug=slug,
            description=description,
            prefix=prefix,
            bucket_rdid=bucket_rdid,
            token=token,
        )

        token_principal_created.additional_properties = d
        return token_principal_created

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
