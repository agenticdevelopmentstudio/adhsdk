from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="SetCreate")


@_attrs_define
class SetCreate:
    """
    Attributes:
        slug (str):
        name (str):
        description (str | Unset):
        is_default (bool | Unset):
        personal_customer_id (None | Unset | UUID): Makes a personal set for this customer of the ecosystem; fixed once
            made.
    """

    slug: str
    name: str
    description: str | Unset = UNSET
    is_default: bool | Unset = UNSET
    personal_customer_id: None | Unset | UUID = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        description = self.description

        is_default = self.is_default

        personal_customer_id: None | str | Unset
        if isinstance(self.personal_customer_id, Unset):
            personal_customer_id = UNSET
        elif isinstance(self.personal_customer_id, UUID):
            personal_customer_id = str(self.personal_customer_id)
        else:
            personal_customer_id = self.personal_customer_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if is_default is not UNSET:
            field_dict["is_default"] = is_default
        if personal_customer_id is not UNSET:
            field_dict["personal_customer_id"] = personal_customer_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description", UNSET)

        is_default = d.pop("is_default", UNSET)

        def _parse_personal_customer_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                personal_customer_id_type_0 = UUID(data)

                return personal_customer_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        personal_customer_id = _parse_personal_customer_id(d.pop("personal_customer_id", UNSET))

        set_create = cls(
            slug=slug,
            name=name,
            description=description,
            is_default=is_default,
            personal_customer_id=personal_customer_id,
        )

        return set_create
