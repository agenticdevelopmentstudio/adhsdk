from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_persona_may_act_kinds_item import RegistryPersonaMayActKindsItem
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1PersonasByIdActorsResponse200")


@_attrs_define
class GetV1PersonasByIdActorsResponse200:
    """
    Attributes:
        kinds (list[RegistryPersonaMayActKindsItem]): the subject kinds this persona may act for (always includes
            'self')
        object_ (Literal['actor'] | Unset):
    """

    kinds: list[RegistryPersonaMayActKindsItem]
    object_: Literal["actor"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kinds = []
        for kinds_item_data in self.kinds:
            kinds_item = kinds_item_data.value
            kinds.append(kinds_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kinds": kinds,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kinds = []
        _kinds = d.pop("kinds")
        for kinds_item_data in _kinds:
            kinds_item = RegistryPersonaMayActKindsItem(kinds_item_data)

            kinds.append(kinds_item)

        object_ = cast(Literal["actor"] | Unset, d.pop("object", UNSET))
        if object_ != "actor" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'actor', got '{object_}'")

        get_v1_personas_by_id_actors_response_200 = cls(
            kinds=kinds,
            object_=object_,
        )

        get_v1_personas_by_id_actors_response_200.additional_properties = d
        return get_v1_personas_by_id_actors_response_200

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
