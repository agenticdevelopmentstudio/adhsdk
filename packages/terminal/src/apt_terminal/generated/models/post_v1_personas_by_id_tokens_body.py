from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_personas_by_id_tokens_body_subject import (
        PostV1PersonasByIdTokensBodySubject,
    )


T = TypeVar("T", bound="PostV1PersonasByIdTokensBody")


@_attrs_define
class PostV1PersonasByIdTokensBody:
    """
    Attributes:
        subject (PostV1PersonasByIdTokensBodySubject):
        name (str | Unset):
        expires_at (datetime.datetime | None | Unset): Omitted/null defaults to a bounded 90-day TTL (never a non-
            expiring token); an explicit value is honored.
    """

    subject: PostV1PersonasByIdTokensBodySubject
    name: str | Unset = UNSET
    expires_at: datetime.datetime | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject = self.subject.to_dict()

        name = self.name

        expires_at: None | str | Unset
        if isinstance(self.expires_at, Unset):
            expires_at = UNSET
        elif isinstance(self.expires_at, datetime.datetime):
            expires_at = self.expires_at.isoformat()
        else:
            expires_at = self.expires_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject": subject,
            }
        )
        if name is not UNSET:
            field_dict["name"] = name
        if expires_at is not UNSET:
            field_dict["expires_at"] = expires_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_personas_by_id_tokens_body_subject import (
            PostV1PersonasByIdTokensBodySubject,
        )

        d = dict(src_dict)
        subject = PostV1PersonasByIdTokensBodySubject.from_dict(d.pop("subject"))

        name = d.pop("name", UNSET)

        def _parse_expires_at(data: object) -> datetime.datetime | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                expires_at_type_0 = datetime.datetime.fromisoformat(data)

                return expires_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None | Unset, data)

        expires_at = _parse_expires_at(d.pop("expires_at", UNSET))

        post_v1_personas_by_id_tokens_body = cls(
            subject=subject,
            name=name,
            expires_at=expires_at,
        )

        post_v1_personas_by_id_tokens_body.additional_properties = d
        return post_v1_personas_by_id_tokens_body

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
