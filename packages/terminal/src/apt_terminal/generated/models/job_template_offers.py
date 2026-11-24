from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="JobTemplateOffers")


@_attrs_define
class JobTemplateOffers:
    """
    Attributes:
        set_ids (list[UUID]):
    """

    set_ids: list[UUID]

    def to_dict(self) -> dict[str, Any]:
        set_ids = []
        for set_ids_item_data in self.set_ids:
            set_ids_item = str(set_ids_item_data)
            set_ids.append(set_ids_item)

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "set_ids": set_ids,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        set_ids = []
        _set_ids = d.pop("set_ids")
        for set_ids_item_data in _set_ids:
            set_ids_item = UUID(set_ids_item_data)

            set_ids.append(set_ids_item)

        job_template_offers = cls(
            set_ids=set_ids,
        )

        return job_template_offers
