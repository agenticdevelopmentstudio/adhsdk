from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentContactsByIdBody")


@_attrs_define
class PostV1ContentContactsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        person_user_id (None | str | Unset):
        full_name (str | Unset):
        nickname (str | Unset):
        email (str | Unset):
        phone (str | Unset):
        notes (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    person_user_id: None | str | Unset = UNSET
    full_name: str | Unset = UNSET
    nickname: str | Unset = UNSET
    email: str | Unset = UNSET
    phone: str | Unset = UNSET
    notes: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        person_user_id: None | str | Unset
        if isinstance(self.person_user_id, Unset):
            person_user_id = UNSET
        else:
            person_user_id = self.person_user_id

        full_name = self.full_name

        nickname = self.nickname

        email = self.email

        phone = self.phone

        notes = self.notes

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if person_user_id is not UNSET:
            field_dict["person_user_id"] = person_user_id
        if full_name is not UNSET:
            field_dict["full_name"] = full_name
        if nickname is not UNSET:
            field_dict["nickname"] = nickname
        if email is not UNSET:
            field_dict["email"] = email
        if phone is not UNSET:
            field_dict["phone"] = phone
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        owner_kind = d.pop("owner_kind", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        def _parse_person_user_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        person_user_id = _parse_person_user_id(d.pop("person_user_id", UNSET))

        full_name = d.pop("full_name", UNSET)

        nickname = d.pop("nickname", UNSET)

        email = d.pop("email", UNSET)

        phone = d.pop("phone", UNSET)

        notes = d.pop("notes", UNSET)

        post_v1_content_contacts_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            person_user_id=person_user_id,
            full_name=full_name,
            nickname=nickname,
            email=email,
            phone=phone,
            notes=notes,
        )

        return post_v1_content_contacts_by_id_body
