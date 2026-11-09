from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1SpecialInterestsByIdBody")


@_attrs_define
class PostV1SpecialInterestsByIdBody:
    """
    Attributes:
        persona_id (str | Unset):
        slug (str | Unset):
        general (str | Unset):
        topical (None | str | Unset):
        specific (None | str | Unset):
        stances (None | str | Unset):
        position (int | Unset):
    """

    persona_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    general: str | Unset = UNSET
    topical: None | str | Unset = UNSET
    specific: None | str | Unset = UNSET
    stances: None | str | Unset = UNSET
    position: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        persona_id = self.persona_id

        slug = self.slug

        general = self.general

        topical: None | str | Unset
        if isinstance(self.topical, Unset):
            topical = UNSET
        else:
            topical = self.topical

        specific: None | str | Unset
        if isinstance(self.specific, Unset):
            specific = UNSET
        else:
            specific = self.specific

        stances: None | str | Unset
        if isinstance(self.stances, Unset):
            stances = UNSET
        else:
            stances = self.stances

        position = self.position

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if persona_id is not UNSET:
            field_dict["persona_id"] = persona_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if general is not UNSET:
            field_dict["general"] = general
        if topical is not UNSET:
            field_dict["topical"] = topical
        if specific is not UNSET:
            field_dict["specific"] = specific
        if stances is not UNSET:
            field_dict["stances"] = stances
        if position is not UNSET:
            field_dict["position"] = position

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        persona_id = d.pop("persona_id", UNSET)

        slug = d.pop("slug", UNSET)

        general = d.pop("general", UNSET)

        def _parse_topical(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        topical = _parse_topical(d.pop("topical", UNSET))

        def _parse_specific(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        specific = _parse_specific(d.pop("specific", UNSET))

        def _parse_stances(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stances = _parse_stances(d.pop("stances", UNSET))

        position = d.pop("position", UNSET)

        post_v1_special_interests_by_id_body = cls(
            persona_id=persona_id,
            slug=slug,
            general=general,
            topical=topical,
            specific=specific,
            stances=stances,
            position=position,
        )

        return post_v1_special_interests_by_id_body
