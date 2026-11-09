from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="TokenPrincipal")


@_attrs_define
class TokenPrincipal:
    """
    Attributes:
        id (str):
        slug (str):
        description (str):
        prefix (str): Non-secret leading chars of the secret, for display
        rdid (None | str): reverse-domain id, e.g. token.<owner-slug>.<name>; null if it has no canonical mapping
        bucket_rdid (None | str): the token’s own isolated bucket, e.g. storage.<owner-slug>.<name>; null if it has no
            canonical mapping
        created (int): Unix timestamp, in seconds.
        expires_at (None | str | Unset):
        last_used_at (None | str | Unset):
    """

    id: str
    slug: str
    description: str
    prefix: str
    rdid: None | str
    bucket_rdid: None | str
    created: int
    expires_at: None | str | Unset = UNSET
    last_used_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        description = self.description

        prefix = self.prefix

        rdid: None | str
        rdid = self.rdid

        bucket_rdid: None | str
        bucket_rdid = self.bucket_rdid

        created = self.created

        expires_at: None | str | Unset
        if isinstance(self.expires_at, Unset):
            expires_at = UNSET
        else:
            expires_at = self.expires_at

        last_used_at: None | str | Unset
        if isinstance(self.last_used_at, Unset):
            last_used_at = UNSET
        else:
            last_used_at = self.last_used_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "description": description,
                "prefix": prefix,
                "rdid": rdid,
                "bucket_rdid": bucket_rdid,
                "created": created,
            }
        )
        if expires_at is not UNSET:
            field_dict["expires_at"] = expires_at
        if last_used_at is not UNSET:
            field_dict["last_used_at"] = last_used_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        description = d.pop("description")

        prefix = d.pop("prefix")

        def _parse_rdid(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        rdid = _parse_rdid(d.pop("rdid"))

        def _parse_bucket_rdid(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        bucket_rdid = _parse_bucket_rdid(d.pop("bucket_rdid"))

        created = d.pop("created")

        def _parse_expires_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        expires_at = _parse_expires_at(d.pop("expires_at", UNSET))

        def _parse_last_used_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_used_at = _parse_last_used_at(d.pop("last_used_at", UNSET))

        token_principal = cls(
            id=id,
            slug=slug,
            description=description,
            prefix=prefix,
            rdid=rdid,
            bucket_rdid=bucket_rdid,
            created=created,
            expires_at=expires_at,
            last_used_at=last_used_at,
        )

        token_principal.additional_properties = d
        return token_principal

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
