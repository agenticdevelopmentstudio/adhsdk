from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentPollsIdBody")


@_attrs_define
class PutContentPollsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        host_kind (None | str | Unset):
        host_id (None | str | Unset):
        question (str | Unset):
        allow_multiple (bool | Unset):
        expires_at (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    host_kind: None | str | Unset = UNSET
    host_id: None | str | Unset = UNSET
    question: str | Unset = UNSET
    allow_multiple: bool | Unset = UNSET
    expires_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        host_kind: None | str | Unset
        if isinstance(self.host_kind, Unset):
            host_kind = UNSET
        else:
            host_kind = self.host_kind

        host_id: None | str | Unset
        if isinstance(self.host_id, Unset):
            host_id = UNSET
        else:
            host_id = self.host_id

        question = self.question

        allow_multiple = self.allow_multiple

        expires_at: None | str | Unset
        if isinstance(self.expires_at, Unset):
            expires_at = UNSET
        else:
            expires_at = self.expires_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if host_kind is not UNSET:
            field_dict["hostKind"] = host_kind
        if host_id is not UNSET:
            field_dict["hostId"] = host_id
        if question is not UNSET:
            field_dict["question"] = question
        if allow_multiple is not UNSET:
            field_dict["allowMultiple"] = allow_multiple
        if expires_at is not UNSET:
            field_dict["expiresAt"] = expires_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_host_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        host_kind = _parse_host_kind(d.pop("hostKind", UNSET))

        def _parse_host_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        host_id = _parse_host_id(d.pop("hostId", UNSET))

        question = d.pop("question", UNSET)

        allow_multiple = d.pop("allowMultiple", UNSET)

        def _parse_expires_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        expires_at = _parse_expires_at(d.pop("expiresAt", UNSET))

        put_content_polls_id_body = cls(
            ecosystem_id=ecosystem_id,
            host_kind=host_kind,
            host_id=host_id,
            question=question,
            allow_multiple=allow_multiple,
            expires_at=expires_at,
        )

        return put_content_polls_id_body
