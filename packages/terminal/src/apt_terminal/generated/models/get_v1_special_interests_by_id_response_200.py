from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SpecialInterestsByIdResponse200")


@_attrs_define
class GetV1SpecialInterestsByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['special_interest'] | Unset):
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
    created: int
    updated: int
    object_: Literal["special_interest"] | Unset = UNSET
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

        created = self.created

        updated = self.updated

        object_ = self.object_

        bucket_type_id: None | str | Unset
        if isinstance(self.bucket_type_id, Unset):
            bucket_type_id = UNSET
        else:
            bucket_type_id = self.bucket_type_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "persona_id": persona_id,
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "general": general,
                "topical": topical,
                "specific": specific,
                "stances": stances,
                "bucket_id": bucket_id,
                "position": position,
                "is_deleted": is_deleted,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if bucket_type_id is not UNSET:
            field_dict["bucket_type_id"] = bucket_type_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        persona_id = d.pop("persona_id")

        def _parse_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        user_id = _parse_user_id(d.pop("user_id"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

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

        bucket_id = _parse_bucket_id(d.pop("bucket_id"))

        position = d.pop("position")

        is_deleted = d.pop("is_deleted")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["special_interest"] | Unset, d.pop("object", UNSET))
        if object_ != "special_interest" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'special_interest', got '{object_}'")

        def _parse_bucket_type_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        bucket_type_id = _parse_bucket_type_id(d.pop("bucket_type_id", UNSET))

        get_v1_special_interests_by_id_response_200 = cls(
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
            created=created,
            updated=updated,
            object_=object_,
            bucket_type_id=bucket_type_id,
        )

        return get_v1_special_interests_by_id_response_200
