from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetPersonaSpecialInterestsResponse200Item")


@_attrs_define
class GetPersonaSpecialInterestsResponse200Item:
    """
    Attributes:
        id (str):
        persona_id (str):
        user_id (None | str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        slug (str):
        general (str):
        topical (None | str):
        specific (None | str):
        stances (None | str):
        bucket_id (None | str):
        position (int):
        is_deleted (bool):
        created_at (str):
        updated_at (str):
        bucket_type_id (None | str | Unset):
    """

    id: str
    persona_id: str
    user_id: None | str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    slug: str
    general: str
    topical: None | str
    specific: None | str
    stances: None | str
    bucket_id: None | str
    position: int
    is_deleted: bool
    created_at: str
    updated_at: str
    bucket_type_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        persona_id = self.persona_id

        user_id: None | str
        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        slug = self.slug

        general = self.general

        topical: None | str
        topical = self.topical

        specific: None | str
        specific = self.specific

        stances: None | str
        stances = self.stances

        bucket_id: None | str
        bucket_id = self.bucket_id

        position = self.position

        is_deleted = self.is_deleted

        created_at = self.created_at

        updated_at = self.updated_at

        bucket_type_id: None | str | Unset
        if isinstance(self.bucket_type_id, Unset):
            bucket_type_id = UNSET
        else:
            bucket_type_id = self.bucket_type_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "personaId": persona_id,
                "userId": user_id,
                "authorKind": author_kind,
                "authorId": author_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "slug": slug,
                "general": general,
                "topical": topical,
                "specific": specific,
                "stances": stances,
                "bucketId": bucket_id,
                "position": position,
                "isDeleted": is_deleted,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if bucket_type_id is not UNSET:
            field_dict["bucketTypeId"] = bucket_type_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        persona_id = d.pop("personaId")

        def _parse_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        user_id = _parse_user_id(d.pop("userId"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        slug = d.pop("slug")

        general = d.pop("general")

        def _parse_topical(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        topical = _parse_topical(d.pop("topical"))

        def _parse_specific(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        specific = _parse_specific(d.pop("specific"))

        def _parse_stances(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        stances = _parse_stances(d.pop("stances"))

        def _parse_bucket_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        bucket_id = _parse_bucket_id(d.pop("bucketId"))

        position = d.pop("position")

        is_deleted = d.pop("isDeleted")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_bucket_type_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        bucket_type_id = _parse_bucket_type_id(d.pop("bucketTypeId", UNSET))

        get_persona_special_interests_response_200_item = cls(
            id=id,
            persona_id=persona_id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            general=general,
            topical=topical,
            specific=specific,
            stances=stances,
            bucket_id=bucket_id,
            position=position,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
            bucket_type_id=bucket_type_id,
        )

        return get_persona_special_interests_response_200_item
