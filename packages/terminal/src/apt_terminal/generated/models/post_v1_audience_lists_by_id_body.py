from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AudienceListsByIdBody")


@_attrs_define
class PostV1AudienceListsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        slug (str | Unset):
        description (None | str | Unset):
        status (str | Unset):
        welcome_template_id (None | str | Unset):
        welcome_back_template_id (None | str | Unset):
        from_name (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    slug: str | Unset = UNSET
    description: None | str | Unset = UNSET
    status: str | Unset = UNSET
    welcome_template_id: None | str | Unset = UNSET
    welcome_back_template_id: None | str | Unset = UNSET
    from_name: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        slug = self.slug

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        status = self.status

        welcome_template_id: None | str | Unset
        if isinstance(self.welcome_template_id, Unset):
            welcome_template_id = UNSET
        else:
            welcome_template_id = self.welcome_template_id

        welcome_back_template_id: None | str | Unset
        if isinstance(self.welcome_back_template_id, Unset):
            welcome_back_template_id = UNSET
        else:
            welcome_back_template_id = self.welcome_back_template_id

        from_name: None | str | Unset
        if isinstance(self.from_name, Unset):
            from_name = UNSET
        else:
            from_name = self.from_name

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if description is not UNSET:
            field_dict["description"] = description
        if status is not UNSET:
            field_dict["status"] = status
        if welcome_template_id is not UNSET:
            field_dict["welcome_template_id"] = welcome_template_id
        if welcome_back_template_id is not UNSET:
            field_dict["welcome_back_template_id"] = welcome_back_template_id
        if from_name is not UNSET:
            field_dict["from_name"] = from_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        name = d.pop("name", UNSET)

        slug = d.pop("slug", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        status = d.pop("status", UNSET)

        def _parse_welcome_template_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        welcome_template_id = _parse_welcome_template_id(d.pop("welcome_template_id", UNSET))

        def _parse_welcome_back_template_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        welcome_back_template_id = _parse_welcome_back_template_id(
            d.pop("welcome_back_template_id", UNSET)
        )

        def _parse_from_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        from_name = _parse_from_name(d.pop("from_name", UNSET))

        post_v1_audience_lists_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            slug=slug,
            description=description,
            status=status,
            welcome_template_id=welcome_template_id,
            welcome_back_template_id=welcome_back_template_id,
            from_name=from_name,
        )

        return post_v1_audience_lists_by_id_body
